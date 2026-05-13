{
  description = "Reproducible environment for the fiscal free lunch paper and code";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          tex = pkgs.texlive.combine {
            inherit (pkgs.texlive)
              scheme-small
              latexmk
              babel-english
              booktabs
              epstopdf-pkg
              footmisc
              geometry
              lm
              marvosym
              mathtools
              microtype
              natbib
              setspace
              caption
              titlesec
              ;
          };
          rEnv = pkgs.rWrapper.override {
            packages = with pkgs.rPackages; [
              tidyverse
            ];
          };
        in
        {
          default = tex;
          r = rEnv;
        }
      );

      apps = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          buildPaper = pkgs.writeShellApplication {
            name = "build-fiscal-free-lunch-paper";
            runtimeInputs = [
              self.packages.${system}.default
            ];
            text = ''
              mkdir -p compilation
              latexmk -pdf -outdir=compilation -interaction=nonstopmode -halt-on-error paper/main.tex
              mkdir -p artifacts
              cp compilation/main.pdf artifacts/fiscal-free-lunch-paper.pdf
            '';
          };
        in
        {
          default = {
            type = "app";
            program = "${buildPaper}/bin/build-fiscal-free-lunch-paper";
          };
          paper = {
            type = "app";
            program = "${buildPaper}/bin/build-fiscal-free-lunch-paper";
          };
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = [
              self.packages.${system}.default
              self.packages.${system}.r
              pkgs.octave
              pkgs.uv
            ];
          };
        }
      );
    };
}
