from __future__ import annotations

from dataclasses import dataclass

import numpy as np
from scipy.linalg import solve

from fiscal_free_lunch.params import Params


VARIABLES = (
    "xV",
    "piV",
    "iV",
    "ypotV",
    "rpotV",
    "debtg",
    "conshk",
    "govshk",
    "lumptax",
    "yV",
    "rV",
)


@dataclass(frozen=True)
class Simulation:
    values: np.ndarray

    def series(self, variable: str) -> np.ndarray:
        return self.values[VARIABLES.index(variable)]


def _shock_path(periods: int, shock: float, params: Params) -> np.ndarray:
    path = np.zeros(periods + 2)
    path[1] = shock
    ar = 1 - params.rho
    for column in range(2, periods + 1):
        path[column] = ar * path[column - 1]
    return path


def simulate(
    *,
    periods: int,
    eps_con: float,
    eps_gov: float,
    params: Params = Params(),
) -> Simulation:
    values = np.zeros((len(VARIABLES), periods + 2))
    conshk = _shock_path(periods, eps_con, params)
    govshk = _shock_path(periods, eps_gov, params)

    ypot = (
        (1 / params.phi_mc * params.sigma_hat)
        * (params.shrgy * govshk + (1 - params.shrgy) * params.nuc * conshk)
    )
    rpot = (
        1
        / params.sigma_hat
        * (1 - 1 / (params.phi_mc * params.sigma_hat))
        * (
            params.shrgy * (govshk - np.roll(govshk, -1))
            + (1 - params.shrgy) * params.nuc * (conshk - np.roll(conshk, -1))
        )
    )
    rpot[-1] = 0.0

    x, pi, i = _solve_x_pi_i(periods, rpot, params)

    lumptax = np.zeros(periods + 2)
    debtg = np.zeros(periods + 2)
    y = x + ypot
    for column in range(1, periods + 1):
        lumptax[column] = params.phi_tax * debtg[column - 1]
        debtg[column] = (
            (1 + params.rbar) * debtg[column - 1]
            + params.shrgy * govshk[column]
            - params.taxsub * params.thetap * (y[column] + params.phi_mc * x[column])
            - lumptax[column]
        )

    values[VARIABLES.index("xV")] = x
    values[VARIABLES.index("piV")] = pi
    values[VARIABLES.index("iV")] = i
    values[VARIABLES.index("ypotV")] = ypot
    values[VARIABLES.index("rpotV")] = rpot
    values[VARIABLES.index("debtg")] = debtg
    values[VARIABLES.index("conshk")] = conshk
    values[VARIABLES.index("govshk")] = govshk
    values[VARIABLES.index("lumptax")] = lumptax
    values[VARIABLES.index("yV")] = y
    values[VARIABLES.index("rV")] = i - np.roll(pi, -1)
    values[VARIABLES.index("rV")][-1] = 0.0
    return Simulation(values)


def _solve_x_pi_i(
    periods: int,
    rpot: np.ndarray,
    params: Params,
    *,
    max_iter: int = 100,
) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    binding = np.zeros(periods, dtype=bool)
    x = np.zeros(periods + 2)
    pi = np.zeros(periods + 2)

    for _ in range(max_iter):
        x, pi = _solve_for_regime(periods, rpot, params, binding)
        taylor = params.gam_pi * pi[1 : periods + 1] + params.gam_xgap * x[1 : periods + 1]
        next_binding = taylor <= -params.ibar
        if np.array_equal(binding, next_binding):
            break
        binding = next_binding
    else:
        raise RuntimeError("ZLB regime iteration did not converge")

    i = np.zeros(periods + 2)
    taylor = params.gam_pi * pi + params.gam_xgap * x
    i[1 : periods + 1] = np.maximum(-params.ibar, taylor[1 : periods + 1])
    return x, pi, i


def _solve_for_regime(
    periods: int,
    rpot: np.ndarray,
    params: Params,
    binding: np.ndarray,
) -> tuple[np.ndarray, np.ndarray]:
    size = 2 * periods
    lhs = np.zeros((size, size))
    rhs = np.zeros(size)

    def x_idx(column: int) -> int:
        return column - 1

    def pi_idx(column: int) -> int:
        return periods + column - 1

    for column in range(1, periods + 1):
        is_row = 2 * (column - 1)
        pc_row = is_row + 1

        if binding[column - 1]:
            lhs[is_row, x_idx(column)] = 1.0
            if column < periods:
                lhs[is_row, x_idx(column + 1)] = -1.0
                lhs[is_row, pi_idx(column + 1)] = -params.sigma_hat
            rhs[is_row] = params.sigma_hat * (params.ibar + rpot[column])
        else:
            lhs[is_row, x_idx(column)] = 1.0 + params.sigma_hat * params.gam_xgap
            lhs[is_row, pi_idx(column)] = params.sigma_hat * params.gam_pi
            if column < periods:
                lhs[is_row, x_idx(column + 1)] = -1.0
                lhs[is_row, pi_idx(column + 1)] = -params.sigma_hat
            rhs[is_row] = params.sigma_hat * rpot[column]

        lhs[pc_row, x_idx(column)] = -params.kappap
        lhs[pc_row, pi_idx(column)] = 1.0
        if column < periods:
            lhs[pc_row, pi_idx(column + 1)] = -params.beta

    solution = solve(lhs, rhs, assume_a="gen")
    x = np.zeros(periods + 2)
    pi = np.zeros(periods + 2)
    x[1 : periods + 1] = solution[:periods]
    pi[1 : periods + 1] = solution[periods:]
    return x, pi


def simulate_no_inflation_response(
    *,
    periods: int,
    eps_con: float,
    eps_gov: float,
    params: Params = Params(),
) -> Simulation:
    return simulate(periods=periods, eps_con=eps_con, eps_gov=eps_gov, params=params)
