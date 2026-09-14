use std::env;
use std::fs;
use std::io::{BufRead, BufReader, Read, Write};
use std::os::unix::net::{UnixListener, UnixStream};
use std::process::{Command, Stdio};
use std::sync::mpsc::{channel, RecvTimeoutError, Sender};
use std::thread;
use std::time::{Duration, Instant};

const OSD_TIMEOUT: Duration = Duration::from_millis(1400);
const ANIM: Duration = Duration::from_millis(420);
const WARMUP: Duration = Duration::from_millis(1000);

#[derive(Clone, Copy, PartialEq)]
enum Status {
    Hidden,
    Shown,
    Hiding,
}

#[derive(Clone, Copy)]
enum BarKind {
    Overview,
    Volume,
    Brightness,
}

struct Bar {
    name: &'static str,
    status: Status,
    deadline: Option<Instant>,
    timeout: Option<Duration>,
}

enum Event {
    Show(BarKind),
    Hide(BarKind),
}

struct Controller {
    ipc_path: String,
    css_path: String,
    last_css: Option<String>,
    bars: [Bar; 3],
}

impl Controller {
    fn new(ipc_path: String, css_path: String) -> Self {
        Controller {
            ipc_path,
            css_path,
            last_css: None,
            bars: [
                Bar {
                    name: "overview",
                    status: Status::Hidden,
                    deadline: None,
                    timeout: None,
                },
                Bar {
                    name: "osd-volume",
                    status: Status::Hidden,
                    deadline: None,
                    timeout: Some(OSD_TIMEOUT),
                },
                Bar {
                    name: "osd-brightness",
                    status: Status::Hidden,
                    deadline: None,
                    timeout: Some(OSD_TIMEOUT),
                },
            ],
        }
    }

    fn warm_up(&mut self) {
        let deadline = Instant::now() + WARMUP;
        for bar in &mut self.bars {
            ipc(&self.ipc_path, &bar_command("show", bar.name));
            bar.status = Status::Shown;
            bar.deadline = Some(deadline);
        }
        self.write_css();
    }

    fn show(&mut self, kind: BarKind) {
        let bar = &mut self.bars[kind as usize];
        if bar.status == Status::Hidden {
            ipc(&self.ipc_path, &bar_command("show", bar.name));
        }
        bar.status = Status::Shown;
        bar.deadline = bar.timeout.map(|timeout| Instant::now() + timeout);
        self.write_css();
    }

    fn hide(&mut self, kind: BarKind) {
        let bar = &mut self.bars[kind as usize];
        if bar.status == Status::Hidden {
            return;
        }
        bar.status = Status::Hiding;
        let deadline = Instant::now() + ANIM;
        if bar.deadline.is_none_or(|current| current < deadline) {
            bar.deadline = Some(deadline);
        }
        self.write_css();
    }

    fn expire(&mut self, now: Instant) {
        for bar in &mut self.bars {
            if !bar.deadline.is_some_and(|deadline| deadline <= now) {
                continue;
            }
            match bar.status {
                Status::Shown => {
                    bar.status = Status::Hiding;
                    bar.deadline = Some(now + ANIM);
                }
                Status::Hiding => {
                    ipc(&self.ipc_path, &bar_command("hide", bar.name));
                    bar.status = Status::Hidden;
                    bar.deadline = None;
                }
                Status::Hidden => bar.deadline = None,
            }
        }
        self.write_css();
    }

    fn write_css(&mut self) {
        let css = self
            .bars
            .iter()
            .map(|bar| {
                let hidden = u8::from(bar.status != Status::Shown);
                format!("#{} {{ --hidden: {hidden}; }}\n", bar.name)
            })
            .collect::<String>();

        if self.last_css.as_deref() == Some(css.as_str()) {
            return;
        }

        fs::write(&self.css_path, &css).unwrap();
        self.last_css = Some(css);
    }

    fn next_deadline(&self) -> Option<Instant> {
        self.bars.iter().filter_map(|bar| bar.deadline).min()
    }

    fn handle(&mut self, event: Event) {
        match event {
            Event::Show(kind) => self.show(kind),
            Event::Hide(kind) => self.hide(kind),
        }
    }
}

fn ipc(path: &str, command: &str) {
    let mut stream = UnixStream::connect(path).unwrap();
    writeln!(stream, "{command}").unwrap();
    let _ = stream.read_to_string(&mut String::new());
}

fn bar_command(subcommand: &str, name: &str) -> String {
    format!(r#"{{"command":"bar","subcommand":"{subcommand}","name":"{name}"}}"#)
}

fn load_css_command(path: &str) -> String {
    format!(r#"{{"command":"style","subcommand":"load_css","path":"{path}"}}"#)
}

fn spawn_control(path: String, tx: Sender<Event>) {
    thread::spawn(move || {
        let _ = fs::remove_file(&path);
        let listener = UnixListener::bind(&path).unwrap();
        for stream in listener.incoming() {
            let stream = stream.unwrap();
            let mut line = String::new();
            BufReader::new(&stream).read_line(&mut line).unwrap();
            match line.trim() {
                "osd volume" => tx.send(Event::Show(BarKind::Volume)).unwrap(),
                "osd brightness" => tx.send(Event::Show(BarKind::Brightness)).unwrap(),
                _ => {}
            }
        }
    });
}

fn spawn_niri(tx: Sender<Event>) {
    thread::spawn(move || {
        let mut child = Command::new("niri")
            .args(["msg", "--json", "event-stream"])
            .stdout(Stdio::piped())
            .spawn()
            .unwrap();
        let stdout = child.stdout.take().unwrap();
        for line in BufReader::new(stdout).lines().map_while(Result::ok) {
            if !line.contains("OverviewOpenedOrClosed") {
                continue;
            }
            let event = if line.contains(r#""is_open":true"#) {
                Event::Show(BarKind::Overview)
            } else {
                Event::Hide(BarKind::Overview)
            };
            if tx.send(event).is_err() {
                break;
            }
        }
    });
}

fn wait_for_ironbar(path: &str) {
    while UnixStream::connect(path).is_err() {
        thread::sleep(Duration::from_millis(200));
    }
}

fn main() {
    let runtime = env::var("XDG_RUNTIME_DIR").unwrap();
    let ipc_path = format!("{runtime}/ironbar-ipc.sock");
    let ctrl_path = format!("{runtime}/ironbar-control.sock");
    let css_path = format!("{runtime}/ironbar-control.css");

    wait_for_ironbar(&ipc_path);

    let mut controller = Controller::new(ipc_path.clone(), css_path.clone());
    controller.warm_up();
    ipc(&ipc_path, &load_css_command(&css_path));

    let (tx, rx) = channel::<Event>();
    spawn_control(ctrl_path, tx.clone());
    spawn_niri(tx);

    loop {
        let now = Instant::now();
        controller.expire(now);

        let event = match controller.next_deadline() {
            Some(deadline) => rx.recv_timeout(deadline.saturating_duration_since(Instant::now())),
            None => rx.recv().map_err(|_| RecvTimeoutError::Disconnected),
        };

        match event {
            Ok(event) => controller.handle(event),
            Err(RecvTimeoutError::Timeout) => {}
            Err(RecvTimeoutError::Disconnected) => break,
        }
    }
}
