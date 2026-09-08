# MiniBash

A Fine tuned .bashrc with Self Made Fetch and trace tracker. Just for Termux

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)
- [Contributing](#contributing)
- [License](#license)

## Features

- Self made fetch Information (Yea, its not Neofetch or smth! Its selfmade!)
- A online Youtube search based using tmux, cava, yt-dlp, and PulseAudio
- A Trace Tracker (Github Like)
- Auto-detect for Proot Distro, And gather they Information

### Tech Stack

- **Bash**

## Installation

```bash
git clone https://github.com/satirrdev/minibash.git
cd minibash
source ~/minibash/.bashrc
chmod +x ~/minibash/satirfetch/start.sh
```

## Usage

```bash
bash
```
To start the Bash

```bash
satirfetch
```

To Show a Minimal fetch Information (**Require a Font with Emoji! For Example, Nerd Font!)

```bash
music
```

To Start a Music search. Available Command is `music`, `music -r`, `music -h`, `music -c`, and `music --landscape`


## Configuration

You can Configure the fetch on `minibash/satirfetch/config.conf`
## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the GPL-3.0 License - see the [LICENSE](LICENSE) file for details.

---

Made with ❤ by [satirrdev](https://github.com/satirrdev)

Note: You need to install Nerd font. And this project just compatbile with Termux
