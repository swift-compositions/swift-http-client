# swift-http-client

Use this package to send an RFC 9110 request and get its response without committing to how it travels. `HTTP.Client` is a value holding one function, `send`, from `IETF.RFC.`9110`.Message.Request<[Byte]>` to `IETF.RFC.`9110`.Message.Response<[Byte]>`, throwing `HTTP.Client.Error`. Build a typed client for a contract on top of it: print the request with swift-http-router, send it, and parse the reply the same router package defines. `HTTP.Client.inProcess(_:)` hands the request to a function in the same process, which is how a test sends every call through a server's answer without a network. `HTTP Client Fetch` gives `HTTP.Client.fetch`, which sends through the browser's `fetch` from Embedded Swift on WebAssembly.

## Laws

- `inProcess(_:)` returns exactly what its function returns and never throws.
- `HTTP.Client.fetch` exists only on wasm32. It throws `.unreachable` when the page reports that `fetch` failed, and `.malformed` when the page's answer is not a response frame.
- A request frame is the method, a line feed, the request target, a line feed, one `name: value` line per field, an empty line, then the body's bytes. A response frame is the status code, a line feed, one `name: value` line per field, an empty line, then the body's bytes. A response frame with no empty line, or whose first line is not a number, is malformed.

## The page's side of fetch

The WebAssembly module imports two functions from the module `http_client_fetch` and exports one; the page supplies the imports:

- `send(id, pointer, count)`: read the request frame at `pointer`, call `fetch`, and when it settles call the export `http_client_fetch_complete(id, count)` with the length of the response frame, or `-1` if `fetch` failed.
- `take(id, pointer, capacity)`: write the response frame for `id` at `pointer` and return its length; the module calls it from inside `http_client_fetch_complete`.

The continuation resumed there is scheduled on the main executor, so the page must run one, as swift-html's DOM mount does.
