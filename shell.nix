{ pkgs ? import <nixpkgs> {} }:
  pkgs.mkShell {
    nativeBuildInputs = [
      pkgs.buildPackages.python3
      pkgs.buildPackages.ruby_3_0
      pkgs.buildPackages.rubyPackages_3_0.pry
    ];
}
