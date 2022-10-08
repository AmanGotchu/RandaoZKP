FROM node:16-buster
COPY . /src
WORKDIR /src


RUN apt update && apt upgrade && apt install curl python3

RUN apt install build-essential libgmp-dev libsodium-dev nasm nlohmann-json3-dev

RUN curl https://sh.rustup.rs -sSf | \
    sh -s -- --default-toolchain nightly -y

ENV PATH=/root/.cargo/bin:$PATH

RUN rustup update

RUN yarn install

RUN git clone https://github.com/iden3/circom.git

RUN cd circom && cargo build --release && cargo install --path circom

RUN curl -LJO https://hermez.s3-eu-west-1.amazonaws.com/powersOfTau28_hez_final_25.ptau

COPY powersOfTau28_hez_final_25.ptau .

