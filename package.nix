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
  version = "0.4.0";

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "westpoint-io";
    repo = "lazyrsync";
    tag = "v${finalAttrs.version}";
    hash = "sha256-v4/UvglfXHmTmotK3wb0czKHyTJbWiDb6uxMuBmkwIo=";
  };

  cargoHash = "sha256-FP5zPyt961m5xCuWdXoYLYcj8vP01X6IgFlDqnhHpOk=";

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
