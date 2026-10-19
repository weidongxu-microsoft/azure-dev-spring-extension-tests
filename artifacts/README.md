# Packed extension

`azure-springboot_0.0.1.zip` is a self-contained development bundle built from
`Azure/azure-dev` commit `f960e452c` with:

```powershell
azd x pack --bundle --rebuild -o <this-directory>
```

It contains macOS, Linux, and Windows artifacts for amd64 and arm64. Verify the
SHA-256 in `SHA256SUMS` before installation.
