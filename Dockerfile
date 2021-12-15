FROM smartnodefr/pythonligo:latest

COPY . .

WORKDIR src/contract

RUN ligo compile contract farm/main.mligo > test/compiled/farm.tz

RUN ligo compile contract database/main.mligo > test/compiled/database.tz

RUN ligo compile contract fa12/fa12.mligo > test/compiled/fa12.tz


WORKDIR test

ENTRYPOINT [ "pytest"]
