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
  version = "0.3.0";

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "westpoint-io";
    repo = "lazyrsync";
    tag = "v${finalAttrs.version}";
    hash = "sha256-cM6FBNXSDOcPkAxf8gNtjaHl1mR7tH383zFIQlPj+GE=";
  };

  cargoHash = "sha256-Qzy9N0km9kw+deg2tfFyffnTrLyuPWRS2yqmuX3CZrQ=";

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
