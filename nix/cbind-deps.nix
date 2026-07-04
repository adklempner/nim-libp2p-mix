# Extra deps needed only by the cbind build (not by the libp2p_mix library).
# taskpools rev matches nim-libp2p's nix/cbind-deps.nix at c431993.
{ pkgs }:

{
  taskpools = pkgs.fetchgit {
    url = "https://github.com/status-im/nim-taskpools";
    rev = "9e8ccc754631ac55ac2fd495e167e74e86293edb";
    sha256 = "1y78l33vdjxmb9dkr455pbphxa73rgdsh8m9gpkf4d9b1wm1yivy";
    fetchSubmodules = true;
  };

}
