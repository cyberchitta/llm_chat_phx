// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";

import TextAreaAutosize from "./text_area_autosize";
import ChatAutoScroll from "./chat_auto_scroll";
import SidebarToggle from "./sidebar_toggle";
import ChatItemMenu from "./chat_item_menu";
import FilePreview from "./file_preview";
import MsgEditAutosize from "./msg_edit_autosize";
import Clipboard from "./clipboard";
import PlayAudio from './play_audio';
import RecordAudio from './record_audio';

let Hooks = {};

Hooks.TextAreaAutosize = TextAreaAutosize;
Hooks.ChatAutoScroll = ChatAutoScroll;
Hooks.SidebarToggle = SidebarToggle;
Hooks.ChatItemMenu = ChatItemMenu;
Hooks.FilePreview = FilePreview;
Hooks.MsgEditAutosize = MsgEditAutosize;
Hooks.Clipboard = Clipboard;
Hooks.PlayAudio = PlayAudio;
Hooks.RecordAudio = RecordAudio;

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {
  hooks: Hooks,
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
