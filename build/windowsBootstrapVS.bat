@echo off

call %2
rake %1 %3 LOOM_BOOTSTRAP_CALL=true