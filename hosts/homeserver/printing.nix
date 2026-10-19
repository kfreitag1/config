{ pkgs, ... }:
{
  services.printing = {
    enable = true;
    startWhenNeeded = false;
    drivers = [ pkgs.brlaser ];
    defaultShared = true;
    browsing = true;
    listenAddresses = [ "*:631" ];
    allowFrom = [ "@LOCAL" ];
    openFirewall = true;
  };

  hardware.printers = {
    ensureDefaultPrinter = "Rhodhouse_Printer";
    ensurePrinters = [
      {
        name = "Rhodhouse_Printer";
        location = "Home";
        description = "Rhodhouse Printer";
        deviceUri = "usb://Brother/HL-L2320D%20series?serial=U63877J7N112105";
        model = "drv:///brlaser.drv/brl2320d.ppd";
        ppdOptions = {
          PageSize = "Letter";
        };
      }
    ];
  };
}
