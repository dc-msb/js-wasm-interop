# C# dotnet 7 builder image

FROM mcr.microsoft.com/dotnet/sdk:7.0 AS csharp-build-env

RUN dotnet workload install wasm-experimental

# copy csharp directory into container
COPY ./csharp /csharp

# set working directory
WORKDIR /csharp

RUN dotnet build -c Release

# rust builder image
FROM rust:latest AS rust-build-env

RUN cargo install wasm-pack cargo-prefetch

RUN cargo prefetch

RUN rustup target add wasm32-unknown-unknown

# set working directory
WORKDIR /rust

# copy rust directory into container
COPY ./rust ./

RUN wasm-pack build --target web --release

# nginx image
FROM python:latest AS app-final

WORKDIR /server

COPY --from=csharp-build-env --chown=root:root /csharp/bin/Release/net7.0/browser-wasm/AppBundle .

COPY --from=rust-build-env --chown=root:root /rust/pkg ./pkg

ENTRYPOINT ["python", "-m", "http.server", "80"]
