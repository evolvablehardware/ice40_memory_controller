with open("temp/custom_data.hex", "w") as f:
  for b in range(16):
    for r in range(256):
      b1 = (r+1)%16
      b0 = (2*r + 1) % 16
      # f.write(f"0{b:01x}0{b:01x}\n")
      f.write(f"0{b0:01x}{b:01x}{b1:01x}\n")