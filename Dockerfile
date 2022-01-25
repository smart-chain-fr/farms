FROM smartnodefr/pythonligo:latest

COPY . .

WORKDIR src/contract

RUN ligo compile contract farm/main.mligo > test/compiled/farm.tz

RUN ligo compile contract database/main.mligo > test/compiled/database.tz

WORKDIR test

ENTRYPOINT [ "pytest"]
