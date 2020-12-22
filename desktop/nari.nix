{ stdenv, lib, fetchFromGitHub }:

stdenv.mkDerivation rec {
  name = "nari-pulse-profile";
  phases = "preInstallPhase";
  src = fetchFromGitHub {
    repo = "razer-nari-pulseaudio-profile";
    owner = "imustafin";
    rev = "91663a51f0c8aaaeddedefa005a46b12ca4592b1";
    sha256 = "1wk5afa09icllx0wv4jks7c5f7ifkki1gr98aagzwmmbf6fcgsq8";
  };
  preInstallPhase = ''
    mkdir -p $out
    cp -r ${src}/* $out
    install -D -t $out/lib/udev/rules.d/ $out/91-pulseaudio-razer-nari.rules
  '';
}
