---- MODULE Session ----
EXTENDS Naturals
CONSTANT Goal
VARIABLES phase, attempts, terminal
vars == <<phase, attempts, terminal>>
Init == /\ phase = "ready" /\ attempts = 0 /\ terminal = "none"
Start == /\ phase = "ready" /\ phase' = "estimating" /\ UNCHANGED <<attempts, terminal>>
Estimate == /\ phase = "estimating" /\ phase' = "feedback" /\ attempts' = attempts + 1 /\ UNCHANGED terminal
Advance == /\ phase = "feedback"
           /\ IF attempts = Goal
                 THEN /\ phase' = "completed" /\ terminal' = "completed"
                 ELSE /\ phase' = "estimating" /\ UNCHANGED terminal
           /\ UNCHANGED attempts
Cancel == /\ phase \in {"ready", "estimating", "feedback"}
          /\ phase' = "cancelled" /\ terminal' = "cancelled" /\ UNCHANGED attempts
Interrupt == /\ phase \in {"estimating", "feedback"}
             /\ phase' = "interrupted" /\ terminal' = "interrupted" /\ UNCHANGED attempts
Next == Start \/ Estimate \/ Advance \/ Cancel \/ Interrupt
Spec == Init /\ [][Next]_vars
TypeOK == /\ phase \in {"ready", "estimating", "feedback", "completed", "cancelled", "interrupted"}
          /\ attempts \in 0..Goal
          /\ terminal \in {"none", "completed", "cancelled", "interrupted"}
TerminalMatches == terminal # "none" => phase = terminal
CompleteHasAllAttempts == phase = "completed" => attempts = Goal
====
