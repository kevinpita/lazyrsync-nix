#!/usr/bin/env bash
set -euo pipefail

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

readonly GITHUB_REPO="westpoint-io/lazyrsync"
readonly PACKAGE_FILE="package.nix"
readonly FAKE_HASH="lib.fakeHash"

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

flake_ref() {
	echo "path:$(pwd -P)#lazyrsync"
}

flake_path() {
	echo "path:$(pwd -P)"
}

get_current_version() {
	sed -n 's/.*version = "\([^"]*\)".*/\1/p' "$PACKAGE_FILE" | head -1
}

get_latest_version() {
	local tag
	tag=$(gh api "repos/$GITHUB_REPO/releases/latest" --jq '.tag_name' 2>/dev/null || echo "")
	if [ -z "$tag" ]; then
		log_error "Failed to fetch latest version from GitHub"
		exit 1
	fi
	echo "${tag#v}"
}

ensure_in_repository_root() {
	if [ ! -f "flake.nix" ] || [ ! -f "$PACKAGE_FILE" ]; then
		log_error "flake.nix or $PACKAGE_FILE not found. Run this script from the repository root."
		exit 1
	fi
}

ensure_required_tools_installed() {
	command -v gh >/dev/null 2>&1 || {
		log_error "gh is required but not installed."
		exit 1
	}
	command -v nix >/dev/null 2>&1 || {
		log_error "nix is required but not installed."
		exit 1
	}
	command -v perl >/dev/null 2>&1 || {
		log_error "perl is required but not installed."
		exit 1
	}
}

validate_version() {
	local version="$1"
	if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+([+-][0-9A-Za-z.-]+)?$ ]]; then
		log_error "Invalid version: $version"
		exit 1
	fi
}

print_usage() {
	echo "Usage: $0 [OPTIONS]"
	echo ""
	echo "Options:"
	echo "  --version VERSION  Update to a specific version"
	echo "  --check            Only check for updates"
	echo "  --help             Show this help message"
}

parse_arguments() {
	local target_version=""
	local check_only=false

	while [[ $# -gt 0 ]]; do
		case "$1" in
		--version)
			if [[ $# -lt 2 ]]; then
				log_error "--version requires a value"
				exit 1
			fi
			target_version="${2#v}"
			shift 2
			;;
		--check)
			check_only=true
			shift
			;;
		--help)
			print_usage
			exit 0
			;;
		*)
			log_error "Unknown option: $1"
			print_usage
			exit 1
			;;
		esac
	done

	echo "$target_version|$check_only"
}

update_version() {
	local version="$1"
	perl -0pi -e "s/version = \"[^\"]+\";/version = \"$version\";/" "$PACKAGE_FILE"
}

set_src_hash() {
	local hash="$1"
	perl -0pi -e "s|(src = fetchFromGitHub \\{.*?hash = )[^;]+;|\${1}\"$hash\";|s" "$PACKAGE_FILE"
}

set_src_fake_hash() {
	perl -0pi -e "s|(src = fetchFromGitHub \\{.*?hash = )[^;]+;|\${1}$FAKE_HASH;|s" "$PACKAGE_FILE"
}

set_cargo_hash() {
	local hash="$1"
	perl -0pi -e "s|cargoHash = [^;]+;|cargoHash = \"$hash\";|" "$PACKAGE_FILE"
}

set_cargo_fake_hash() {
	perl -0pi -e "s|cargoHash = [^;]+;|cargoHash = $FAKE_HASH;|" "$PACKAGE_FILE"
}

extract_got_hash() {
	local log_file="$1"
	sed -n 's/.*got:[[:space:]]*\(sha256-[A-Za-z0-9+\/=]*\).*/\1/p' "$log_file" | tail -1
}

expect_hash_mismatch() {
	local label="$1"
	local log_file
	log_file=$(mktemp)

	set +e
	nix build "$(flake_ref)" --no-link --print-build-logs >"$log_file" 2>&1
	local status=$?
	set -e

	if [ "$status" -eq 0 ]; then
		log_error "Expected a hash mismatch while updating $label, but the build succeeded"
		cat "$log_file"
		exit 1
	fi

	local hash
	hash=$(extract_got_hash "$log_file")
	if [ -z "$hash" ]; then
		log_error "Failed to extract replacement hash for $label"
		cat "$log_file"
		exit 1
	fi

	echo "$hash"
}

refresh_hashes() {
	log_info "Refreshing source hash"
	set_src_fake_hash
	set_src_hash "$(expect_hash_mismatch "source")"

	log_info "Refreshing Cargo hash"
	set_cargo_fake_hash
	set_cargo_hash "$(expect_hash_mismatch "Cargo dependencies")"
}

verify_update() {
	local expected_version="$1"

	log_info "Building lazyrsync"
	nix build "$(flake_ref)" --print-build-logs

	log_info "Checking lazyrsync version"
	local actual_version
	actual_version=$(./result/bin/lazyrsync --version)
	if [ "$actual_version" != "lazyrsync $expected_version" ]; then
		log_error "Expected lazyrsync $expected_version, got: $actual_version"
		exit 1
	fi
	echo "$actual_version"
}

update_flake_lock() {
	log_info "Updating flake.lock"
	nix flake update --flake "$(flake_path)"
}

show_changes() {
	echo ""
	log_info "Changes made:"
	git diff --stat "$PACKAGE_FILE" flake.lock 2>/dev/null || true
}

update_to_version() {
	local current_version="$1"
	local new_version="$2"

	cp "$PACKAGE_FILE" "$PACKAGE_FILE.bak"
	trap 'mv -f "$PACKAGE_FILE.bak" "$PACKAGE_FILE"' ERR INT TERM

	log_info "Updating lazyrsync from $current_version to $new_version"
	update_version "$new_version"
	refresh_hashes
	verify_update "$new_version"
	update_flake_lock

	rm -f "$PACKAGE_FILE.bak"
	trap - ERR INT TERM
	show_changes
}

main() {
	ensure_in_repository_root
	ensure_required_tools_installed

	local args
	args=$(parse_arguments "$@")
	local target_version
	target_version=$(echo "$args" | cut -d'|' -f1)
	local check_only
	check_only=$(echo "$args" | cut -d'|' -f2)

	local current_version
	current_version=$(get_current_version)
	local latest_version
	latest_version=$(get_latest_version)

	if [ -n "$target_version" ]; then
		latest_version="$target_version"
	fi
	validate_version "$latest_version"

	log_info "Current version: $current_version"
	log_info "Latest version: $latest_version"

	if [ "$current_version" = "$latest_version" ]; then
		log_info "Already up to date"
		exit 0
	fi

	if [ "$check_only" = true ]; then
		log_info "Update available: $current_version -> $latest_version"
		exit 1
	fi

	update_to_version "$current_version" "$latest_version"
}

main "$@"
