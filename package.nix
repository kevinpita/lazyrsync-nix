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
  version = "0.2.0";

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "westpoint-io";
    repo = "lazyrsync";
    tag = "v${finalAttrs.version}";
    hash = "sha256-GKTHohpA9h+uqJS2dwgjMmGfl3KRbmE9Jt94YbprVKE=";
  };

  cargoHash = "sha256-OE7TCcPRDqbtVXN/VDO4HckM6woV/0gzfNr8Di+m1Oo=";

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
