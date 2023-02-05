import "phoenix_html"
import {Socket} from "phoenix"
import NProgress from "nprogress"
import {LiveSocket} from "phoenix_live_view"

const NumericSlider = {
  mounted() {
    this.el.addEventListener("change", e => {
      const meta = this.__view.extractMeta(this.el, {});

      this.pushEvent(
        "device_change",
        {
          characteristic: meta.characteristic,
          device_id: meta['device-id'],
          value: meta.value
        }
      );
    })
  }
};

const hooks = {
  NumericSlider,
};

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}, hooks});

// Show progress bar on live navigation and form submits
window.addEventListener("phx:page-loading-start", info => NProgress.start())
window.addEventListener("phx:page-loading-stop", info => NProgress.done())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket
liveSocket.enableDebug();
