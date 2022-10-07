snarkjs groth16 setup ../main.r1cs ./pot24_final.ptau blockheader_0000.zkey && \
snarkjs zkey contribute blockheader_0000.zkey blockheader_0001.zkey --name="1st Contributor Name" -v && \
snarkjs zkey export verificationkey blockheader_0001.zkey verification_key.json