FROM smartnodefr/pythonligo:latest

COPY . .

WORKDIR /contract

RUN ligo compile contract src/contract/farm/main.mligo > src/contract/test/compiled/farm.tz

RUN ligo compile contract src/contract/database/main.mligo > src/contract/test/compiled/database.tz

WORKDIR /contract/test

ENTRYPOINT [ "pytest"]