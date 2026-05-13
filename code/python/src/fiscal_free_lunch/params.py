from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class Params:
    beta: float = 0.995
    alpha: float = 0.3
    sigma: float = 1.0
    chi: float = 2.5
    shrgy: float = 0.2
    nuc: float = 0.01
    xip: float = 1.0
    gam_xgap: float = 66.15
    gam_pi: float = 66.15
    rho: float = 0.1
    phi_tax: float = 0.01
    thetap: float = 0.7
    sig_con: float = 29.2
    sig_gov: float = 0.05
    pibar: float = 1.005

    @property
    def rbar(self) -> float:
        return (1 / self.beta) - 1

    @property
    def ibar(self) -> float:
        return (self.pibar / self.beta) - 1

    @property
    def sigma_hat(self) -> float:
        return self.sigma * (1 - self.shrgy) * (1 - self.nuc)

    @property
    def phi_mc(self) -> float:
        return (
            self.chi / (1 - self.alpha)
            + 1 / self.sigma_hat
            + self.alpha / (1 - self.alpha)
        )

    @property
    def kappap(self) -> float:
        return (1 - self.xip) * (1 - self.beta * self.xip) / self.xip * self.phi_mc

    @property
    def taxsub(self) -> float:
        return self.shrgy / self.thetap
