{
  lib,
  rustPlatform,
  fetchFromGitHub,
  makeWrapper,
  openssh,
  rsync,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "lazyrsync";
  version = "0.1.1";

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "westpoint-io";
    repo = "lazyrsync";
    tag = "v${finalAttrs.version}";
    hash = "sha256-JBELPmNSaiwxHq9iZHvvrCX/YLSBsOO3OrzXJ0mPrNw=";
  };

  cargoHash = "sha256-/L6N08TFqwW6yeNFiIUtmz6SxdEuxa6SHMxDoZ4Myl8=";

  nativeBuildInputs = [ makeWrapper ];
  nativeCheckInputs = [ rsync ];

  postInstall = ''
    wrapProgram "$out/bin/lazyrsync" \
      --prefix PATH : "${
        lib.makeBinPath [
          rsync
          openssh
        ]
      }"
  '';

  meta = {
    description = "Friendly terminal UI for rsync";
    homepage = "https://github.com/westpoint-io/lazyrsync";
    changelog = "https://github.com/westpoint-io/lazyrsync/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ kevinpita ];
    mainProgram = "lazyrsync";
    platforms = lib.platforms.unix;
  };
})
