# global lua.util.lsp








---

## methods
---

### M.capabilities
---
```lua
function M.capabilities() -> capabilities lsp.ClientCapabilities {
    workspace = lsp.WorkspaceClientCapabilities?,
    textDocument = lsp.TextDocumentClientCapabilities?,
    notebookDocument = lsp.NotebookDocumentClientCapabilities?,
    window = lsp.WindowClientCapabilities?,
    general = lsp.GeneralClientCapabilities?,
    experimental = lsp.LSPAny?,
}
```





Client capabilities advertised to every LSP server: Neovim's own
defaults merged with blink.cmp's completion-related capabilities.








### M.diagnostic
---
```lua
function M.diagnostic() ->  nil
```





Applies this config's global `vim.diagnostic.config()`.








### M.goto_declaration
---
```lua
function M.goto_declaration(
  buf: integer,
  lhs: string?,
  desc: string?
) ->  nil
```
@param `lhs` - Default: "gD"

@param `desc` - Default: "LSP: Goto declaration"






Maps lhs to `vim.lsp.buf.declaration`, buffer-local.








### M.goto_definition
---
```lua
function M.goto_definition(
  buf: integer,
  lhs: string?,
  desc: string?
) ->  nil
```
@param `lhs` - Default: "gd"

@param `desc` - Default: "LSP: Goto definition"






Maps lhs to `vim.lsp.buf.definition`, buffer-local.








### M.goto_implementation
---
```lua
function M.goto_implementation(
  buf: integer,
  lhs: string?,
  desc: string?
) ->  nil
```
@param `lhs` - Default: "gi"

@param `desc` - Default: "LSP: Goto implementation"






Maps lhs to `vim.lsp.buf.implementation`, buffer-local.








### M.goto_references
---
```lua
function M.goto_references(
  buf: integer,
  lhs: string?,
  desc: string?
) ->  nil
```
@param `lhs` - Default: "gr"

@param `desc` - Default: "LSP: List references"






Maps lhs to `vim.lsp.buf.references`, buffer-local.








### M.goto_type_definition
---
```lua
function M.goto_type_definition(
  buf: integer,
  lhs: string?,
  desc: string?
) ->  nil
```
@param `lhs` - Default: "gy"

@param `desc` - Default: "LSP: Goto type definition"






Maps lhs to `vim.lsp.buf.type_definition`, buffer-local.








### M.hover
---
```lua
function M.hover(
  buf: integer,
  lhs: string?,
  desc: string?
) ->  nil
```
@param `lhs` - Default: "K"

@param `desc` - Default: "LSP: Hover documentation"






Maps lhs to `vim.lsp.buf.hover`, buffer-local.








### M.rename
---
```lua
function M.rename(
  buf: integer,
  lhs: string?,
  desc: string?
) ->  nil
```
@param `lhs` - Default: "<leader>cr"

@param `desc` - Default: "LSP: Rename symbol"






Maps lhs to `vim.lsp.buf.rename`, buffer-local.








### M.code_action
---
```lua
function M.code_action(
  buf: integer,
  lhs: string?,
  desc: string?
) ->  nil
```
@param `lhs` - Default: "<leader>ca"

@param `desc` - Default: "LSP: Code action"






Maps lhs to `vim.lsp.buf.code_action` (normal and visual), buffer-local.








### M.incoming_calls
---
```lua
function M.incoming_calls(
  buf: integer,
  lhs: string?,
  desc: string?
) ->  nil
```
@param `lhs` - Default: "<leader>ci"

@param `desc` - Default: "LSP: Incoming calls"






Maps lhs to `vim.lsp.buf.incoming_calls`, buffer-local.








### M.outgoing_calls
---
```lua
function M.outgoing_calls(
  buf: integer,
  lhs: string?,
  desc: string?
) ->  nil
```
@param `lhs` - Default: "<leader>co"

@param `desc` - Default: "LSP: Outgoing calls"






Maps lhs to `vim.lsp.buf.outgoing_calls`, buffer-local.








### M.diagnostic_prev
---
```lua
function M.diagnostic_prev(
  buf: integer,
  lhs: string?,
  desc: string?
) ->  nil
```
@param `lhs` - Default: "[d"

@param `desc` - Default: "LSP: Previous diagnostic"






Maps lhs to jump to and float the previous diagnostic, buffer-local.








### M.diagnostic_next
---
```lua
function M.diagnostic_next(
  buf: integer,
  lhs: string?,
  desc: string?
) ->  nil
```
@param `lhs` - Default: "]d"

@param `desc` - Default: "LSP: Next diagnostic"






Maps lhs to jump to and float the next diagnostic, buffer-local.








### M.diagnostic_open_float
---
```lua
function M.diagnostic_open_float(
  buf: integer,
  lhs: string?,
  desc: string?
) ->  nil
```
@param `lhs` - Default: "<leader>e"

@param `desc` - Default: "LSP: Open diagnostic float"






Maps lhs to `vim.diagnostic.open_float`, buffer-local.








### M.diagnostics_workspace
---
```lua
function M.diagnostics_workspace(
  buf: integer,
  lhs: string?,
  desc: string?
) ->  nil
```
@param `lhs` - Default: "<leader>eq"

@param `desc` - Default: "LSP: Diagnostics (workspace)"






Maps lhs to fzf-lua's workspace diagnostics picker, buffer-local.








### M.diagnostics_document
---
```lua
function M.diagnostics_document(
  buf: integer,
  lhs: string?,
  desc: string?
) ->  nil
```
@param `lhs` - Default: "<leader>el"

@param `desc` - Default: "LSP: Diagnostics (document)"






Maps lhs to fzf-lua's document diagnostics picker, buffer-local.








### M.document_symbols
---
```lua
function M.document_symbols(
  buf: integer,
  lhs: string?,
  desc: string?
) ->  nil
```
@param `lhs` - Default: "<leader>ss"

@param `desc` - Default: "LSP: Document symbols"






Maps lhs to fzf-lua's document symbols picker, buffer-local.








### M.workspace_symbols
---
```lua
function M.workspace_symbols(
  buf: integer,
  lhs: string?,
  desc: string?
) ->  nil
```
@param `lhs` - Default: "<leader>sS"

@param `desc` - Default: "LSP: Workspace symbols"






Maps lhs to fzf-lua's workspace symbols picker, buffer-local.








### M.signature_help_on_type
---
```lua
function M.signature_help_on_type(
  buf: integer,
  client: vim.lsp.Client {
    attached_buffers = table<integer,string>,
    capabilities = lsp.ClientCapabilities,
    commands = table<string,fun(command: lsp.Command, ctx: table)>,
    config = vim.lsp.ClientConfig,
    dynamic_capabilities = lsp.DynamicCapabilities,
    exit_timeout = (boolean|integer),
    flags = vim.lsp.Client.Flags,
    handlers = table<string,lsp.Handler>,
    id = integer,
    initialized = true?,
    name = string,
    offset_encoding = ("utf-8"|"utf-16"|"utf-32"),
    progress = vim.lsp.Client.Progress,
    requests = table<integer,{ bufnr: integer, method: string, ... }?>,
    root_dir = string?,
    rpc = vim.lsp.rpc.PublicClient,
    server_capabilities = lsp.ServerCapabilities?,
    server_info = lsp.ServerInfo?,
    settings = lsp.LSPObject,
    workspace_folders = lsp.WorkspaceFolder[]?,
    _enabled_capabilities = table<vim.lsp.capability.Name,boolean?>,
    _otf_enabled = boolean?,
    _shutdown_timer = uv.uv_timer_t?,
    _graceful_shutdown_failed = true?,
    _trace = ("off"|"messages"|"verbose"),
    registrations = table<string,lsp.Registration[]>,
    _log_prefix = string,
    _before_init_cb = vim.lsp.client.before_init_cb?,
    _on_attach_cbs = vim.lsp.client.on_attach_cb[],
    _on_init_cbs = vim.lsp.client.on_init_cb[],
    _on_exit_cbs = vim.lsp.client.on_exit_cb[],
    _on_error_cb = (fun(code: integer, err: string))?,
    __index = vim.lsp.Client,
    _is_stopping = false,
    messages = { name = string, messages = table, progress = table, status = table, ... },
    _all = table<integer,vim.lsp.Client>,
    get_language_id = function,
    create = function,
    _run_callbacks = function,
    initialize = function,
    _process_static_registrations = function,
    _resolve_handler = function,
    _process_request = function,
    request = function,
    request_sync = function,
    notify = function,
    cancel_request = function,
    stop = function,
    _restart = function,
    _handle_restart = function,
    _supports_registration = function,
    _registration_provider = function,
    _register_dynamic = function,
    _register = function,
    _unregister_dynamic = function,
    _unregister = function,
    _get_language_id = function,
    _get_registrations = function,
    is_stopped = function,
    exec_cmd = function,
    _text_document_did_close_handler = function,
    _text_document_did_open_handler = function,
    on_attach = function,
    write_error = function,
    supports_method = function,
    _provider_foreach = function,
    _notification = function,
    _server_request = function,
    _on_error = function,
    _on_detach = function,
    _on_exit = function,
    _add_workspace_folder = function,
    _remove_workspace_folder = function,
}
) ->  nil
```





Popup showing the active parameter of the function being called,
while typing its arguments. Only wired up for clients that actually
advertise signatureHelpProvider, using their own trigger characters
rather than assuming "(" and ",".








### M.on_attach
---
```lua
function M.on_attach(
  buf: integer,
  client: vim.lsp.Client {
    attached_buffers = table<integer,string>,
    capabilities = lsp.ClientCapabilities,
    commands = table<string,fun(command: lsp.Command, ctx: table)>,
    config = vim.lsp.ClientConfig,
    dynamic_capabilities = lsp.DynamicCapabilities,
    exit_timeout = (boolean|integer),
    flags = vim.lsp.Client.Flags,
    handlers = table<string,lsp.Handler>,
    id = integer,
    initialized = true?,
    name = string,
    offset_encoding = ("utf-8"|"utf-16"|"utf-32"),
    progress = vim.lsp.Client.Progress,
    requests = table<integer,{ bufnr: integer, method: string, ... }?>,
    root_dir = string?,
    rpc = vim.lsp.rpc.PublicClient,
    server_capabilities = lsp.ServerCapabilities?,
    server_info = lsp.ServerInfo?,
    settings = lsp.LSPObject,
    workspace_folders = lsp.WorkspaceFolder[]?,
    _enabled_capabilities = table<vim.lsp.capability.Name,boolean?>,
    _otf_enabled = boolean?,
    _shutdown_timer = uv.uv_timer_t?,
    _graceful_shutdown_failed = true?,
    _trace = ("off"|"messages"|"verbose"),
    registrations = table<string,lsp.Registration[]>,
    _log_prefix = string,
    _before_init_cb = vim.lsp.client.before_init_cb?,
    _on_attach_cbs = vim.lsp.client.on_attach_cb[],
    _on_init_cbs = vim.lsp.client.on_init_cb[],
    _on_exit_cbs = vim.lsp.client.on_exit_cb[],
    _on_error_cb = (fun(code: integer, err: string))?,
    __index = vim.lsp.Client,
    _is_stopping = false,
    messages = { name = string, messages = table, progress = table, status = table, ... },
    _all = table<integer,vim.lsp.Client>,
    get_language_id = function,
    create = function,
    _run_callbacks = function,
    initialize = function,
    _process_static_registrations = function,
    _resolve_handler = function,
    _process_request = function,
    request = function,
    request_sync = function,
    notify = function,
    cancel_request = function,
    stop = function,
    _restart = function,
    _handle_restart = function,
    _supports_registration = function,
    _registration_provider = function,
    _register_dynamic = function,
    _register = function,
    _unregister_dynamic = function,
    _unregister = function,
    _get_language_id = function,
    _get_registrations = function,
    is_stopped = function,
    exec_cmd = function,
    _text_document_did_close_handler = function,
    _text_document_did_open_handler = function,
    on_attach = function,
    write_error = function,
    supports_method = function,
    _provider_foreach = function,
    _notification = function,
    _server_request = function,
    _on_error = function,
    _on_detach = function,
    _on_exit = function,
    _add_workspace_folder = function,
    _remove_workspace_folder = function,
}
) ->  nil
```





Wires up every buffer-local LSP keymap and signature help, called from
an `LspAttach` autocmd.








### M.setup
---
```lua
function M.setup() ->  nil
```





Applies global diagnostic config and capabilities, and wires
`M.on_attach` up to `LspAttach`.











