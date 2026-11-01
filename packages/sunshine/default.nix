{
  lib,
  stdenv,
  src,
  version ? "2026.1028.122642",
  branch ? "fix/macos-4k60",
  rev ? (src.rev or "unknown"),
  fetchzip,
  buildNpmPackage,
  cmake,
  pkg-config,
  python3,
  makeWrapper,
  qt6,
  boost,
  curl,
  miniupnpc,
  nlohmann_json,
  openssl,
  libopus,
  apple-sdk_15,
  darwinMinVersionHook,
}:
let
  ffmpegPrebuilt = fetchzip {
    url = "https://github.com/LizardByte/build-deps/releases/download/v2026.1017.131201/Darwin-arm64-ffmpeg.tar.gz";
    hash = "sha256-EHph04ckDl2tPKhTJvY/RC/BNzHMSYv4ATIXnS5jPiQ=";
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "sunshine";
  inherit version src;

  __structuredAttrs = true;
  strictDeps = true;

  ui = buildNpmPackage {
    pname = "sunshine-ui";
    inherit (finalAttrs) src version;
    npmDepsHash = "sha256-I908PQ4CSiJEbOmi75/0GWnm6iZIUWEsGsmV3XnuN5U=";
    installPhase = ''
      runHook preInstall
      mkdir -p "$out"
      cp -a . "$out"/
      runHook postInstall
    '';
  };

  nativeBuildInputs = [
    cmake
    pkg-config
    (python3.withPackages (ps: [
      ps.jinja2
      ps.setuptools
    ]))
    makeWrapper
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    boost
    curl
    miniupnpc
    nlohmann_json
    openssl
    libopus
    qt6.qtbase
    qt6.qtsvg
    apple-sdk_15
    (darwinMinVersionHook "14.2")
  ];

  cmakeFlags = [
    "-Wno-dev"
    (lib.cmakeBool "BOOST_USE_STATIC" false)
    (lib.cmakeBool "BUILD_DOCS" false)
    (lib.cmakeFeature "SUNSHINE_PUBLISHER_NAME" "kieran")
    (lib.cmakeFeature "SUNSHINE_PUBLISHER_WEBSITE" "https://github.com/kfreitag1/Sunshine")
    (lib.cmakeFeature "SUNSHINE_PUBLISHER_ISSUE_URL" "https://github.com/kfreitag1/Sunshine/issues")
    (lib.cmakeFeature "FFMPEG_PREPARED_BINARIES" "${ffmpegPrebuilt}")
    (lib.cmakeBool "GLAD_SKIP_PIP_INSTALL" true)
    (lib.cmakeBool "SUNSHINE_ENABLE_CUDA" false)
    (lib.cmakeFeature "CMAKE_CXX_STANDARD" "23")
    (lib.cmakeFeature "OPENSSL_ROOT_DIR" "${openssl.dev}")
    (lib.cmakeFeature "SUNSHINE_ASSETS_DIR" "sunshine/assets")
    (lib.cmakeBool "SUNSHINE_BUILD_HOMEBREW" true)
  ];

  env = {
    BUILD_VERSION = version;
    BRANCH = branch;
    COMMIT = rev;
  };

  preBuild = ''
    cp -r ${finalAttrs.ui}/build ../
  '';

  buildFlags = [ "sunshine" ];

  installPhase = ''
    runHook preInstall
    cmake --install .
    runHook postInstall
  '';

  dontWrapQtApps = true;

  postFixup = ''
    wrapProgram $out/bin/sunshine "''${qtWrapperArgs[@]}"
  '';

  postPatch = ''
    substituteInPlace cmake/targets/common.cmake \
      --replace-fail 'find_program(NPM npm REQUIRED)' ""

    sed -i -E 's/set\(BOOST_VERSION "[^"]*"\)/set(BOOST_VERSION "${boost.version}")/' \
      cmake/dependencies/Boost_Sunshine.cmake
    echo 'set(FETCH_CONTENT_BOOST_USED TRUE)' >> cmake/dependencies/Boost_Sunshine.cmake

    substituteInPlace cmake/compile_definitions/common.cmake \
      --replace-fail 'if(APPLE OR CMAKE_SYSTEM_NAME STREQUAL "FreeBSD")' 'if(CMAKE_SYSTEM_NAME STREQUAL "FreeBSD")' \
      --replace-fail 'list(APPEND SUNSHINE_COMPILE_OPTIONS -fexperimental-library)' "" \
      --replace-fail 'list(APPEND SUNSHINE_LINK_OPTIONS -fexperimental-library)' ""

    substituteInPlace third-party/libvirtualhid/src/CMakeLists.txt \
      --replace-fail 'target_compile_options(''${target_name} PUBLIC -fexperimental-library)' "" \
      --replace-fail 'target_link_options(''${target_name} PUBLIC -fexperimental-library)' ""

    substituteInPlace third-party/libvirtualhid/src/platform/macos/broker/CMakeLists.txt \
      --replace-fail 'target_compile_options(libvirtualhid_macos_broker PRIVATE -fexperimental-library)' "" \
      --replace-fail 'target_link_options(libvirtualhid_macos_broker PRIVATE -fexperimental-library)' ""
  '';

  meta = {
    description = "Game stream host for Moonlight";
    homepage = "https://github.com/LizardByte/Sunshine";
    license = lib.licenses.gpl3Only;
    mainProgram = "sunshine";
    platforms = [ "aarch64-darwin" ];
  };
})
