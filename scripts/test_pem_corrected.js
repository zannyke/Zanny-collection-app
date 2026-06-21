const privateKey = `-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDbHMCdZfb8iVjL
0BwvUhDkuVu30UWHh3Rtb/aj5iRSEWMWQcL66GOD5+3JVKr4W4wV0I2NLaxIVDKe
nYXg6ZyfIgjp/PyfNsiIa8Xv9oM+j3ErCl3mxu5qeQFMt/j388HrK5QgV/6S7JvT
vcwK2oBvEVUQQN32aRjCZrvk3D/U+FJkObdgxK1HJ4HiwHeM6IPoz49ZGM+4PAH1
YvIdeRkfX1CXaMckk40dXj3BQfBzEcDdfP1b025jBHUHpL7ymz7TbVXsLUZKihPS
RXHMhIFGzkZFVXKI9OQQ9Qg/u2KCNojk1KPzBJ5bGYjOVbFnhKglL6P0c+TiCyVz
k5Ahbmq9AgMBAAECggEANjNVFDpaT9rby8LljfETe7i8Tuql8+IWc1HMZXuzBVgG
tkU7KZzdrQ3snK5kgn4G14iY01D2eofVY7YcnWe8VgLxyIvLo8jF7zUVqAfHLG0I
NfjhBIq2BEF9iFBD9nXmRLmpcRzDPO3pmAWtmQu21IKpk5UwMtmJheEq3nB7G7+C
TuCqolCbZKTXNJ/JxmPHfoeqEcAJ5H/29v4kW1WhdgHvU/L0H1ExxL/dI0ejT9Nn
j0c8RRWfbBuDT9WNwaMptOjzfxNvVuBg/TplR7iInMVg3Tb3CR6wCbHkrbolHE/5
TAQXx/sklxWsUjqQhCAfNOqVXvyOGzaIIkaF+K660QKBgQDzUY8kjWdBcllYapD3
KwmS2LpPi1dC4Rfvny3BRcnaOhxOV48WVwce0OJG974+LRG29xPvyJcxE3kgd4s9
AyJEFcnoHFupiJ+78LDFvGC+uQsjL+vreudLhnKhYMRoPcc7jChGLK4wTDs0bFCn
eFjh6DJLpt7Q6zu17Fiog3yWQKBgQDmiDmIGITZRMUBZE3w1Dz6/ZrPZR8YZybL
0lFHJeYblYiIS5xC8l5n53ktuweNTHyoPnc1iarhfyfq8ASTJx1GMLTxZFluxAxsCB
p79AzJBd82MVptYs5LM+YflsLMdqubcSWbOUBkMHe3wH0AgCfhmGBbJhYF0vG5cs
wBUdzkJHBQKBgQCjLDjgfGuYekTshFq/Rv9emTUojvtwAF/69DbM/C5HyNyetR1i
D+7YfaChkxbjv3m3x655CX5LDRIX8dNQkT9zhWEn5Yya/uKQOPNzR8dhX9rWOBbw
jjV6cqmBC9HrTjLD/lQr617NSPITT+gvGIjcJGJxSG5AlbvtWHy+9op/0QKBgEVx
nt9L1f99rReU7b/ciGBSLnLzo+0sAl8FCY9WI5x5cFzrne/T2ydWG9wv9kTLRXaPY
3VQ1WlJ/WWj+UIJ7f+gK+BbXYqrotEjaXVSJyttiW/DDxzTS1+Ps45PgkVnnA+z1
NJFcqYhxfFVmJ2OI1Ot4f9mxi6CLMSj72+CUp4Z5AoGAbLSdSiZo3+WqqrJa5TDZ
pGE1YuuINFINb0u/+UFqN0+DLpqs75PM6geobeivrm4gbA8kbYJRgwn+KmNXYtRL
YTzo99usCZDOtUJKMLnFQ39uEvc3euvGeYjF4Fmx0n4EPTOqxB2mHC2IPWjVWxwz
Jm8bgJjy4sgJI0SZvOrzJgc=
-----END PRIVATE KEY-----`;

const b64 = privateKey
  .replace(/-----BEGIN PRIVATE KEY-----/, "")
  .replace(/-----END PRIVATE KEY-----/, "")
  .replace(/\s/g, "")
  .replace(/\\n/g, "");

console.log("Base64 length:", b64.length);
try {
  const binary = atob(b64);
  console.log("Success! Decoded length:", binary.length);
} catch (err) {
  console.log("Error:", err.message);
}
