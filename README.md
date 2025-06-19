# flutter_foundation_models

Flutter port of the FoundationModels framework with Tool and Generable support. Check the [example](flutter_foundation_models/example) for example usage.

Obviously way too raw to use anywhere near production. The codegen package is a semi-vibe-coded nightmare. The API is missing a good half of the features from the original framework. The Swift part may crash due to bad energy or a solar flare, has almost zero type safety, and is about as easy to read as your medicine prescriptions.

But hey, it works — and if someone _really_ needs it, it wouldn't take much to make it more production-ready.

## TODO:

- Use `json_serializable`. Gotta admit, reinventing the wheel there was not my brightest idea.

- Maybe use Pigeon, that still wouldn't fix all method channel issues, but since it finally support sealed classes...

- Fix session deinit, because you know, `deinit` isn't a thing in Flutter.

- Support more APIs and lower iOS versions so it can be used in production.

## Contributing

Feel free to open an issue or a pull request — I’ll try to respond as soon as possible.

## License

MIT
