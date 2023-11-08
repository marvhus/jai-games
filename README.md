# Jai Games
A collection of games I have written using the Jai Programming Language.

## Compiler Version
```console
$ jai -version
Version: beta 0.1.076, built on 22 October 2023.
```

## Instructions

### Build
<details>

```console
$ ./build.jai - <path>
```
The compiler will then generate a binary in the `bin` directory.

For pong that would be:
```console
$ ./build.jai - pong
```
The compiler will generate a binary named `pong` in the `bin` directory.
</details>


### Build & Run
<details>

```console
$ ./build.jai - <path> run
```
You can then pass the arguments you want to give to the executable after the `run` argument.  
For example: `./build.jai - run foo bar baz`.

For pong that would be:
```console
$ ./build.jai - pong run
```
</details>

