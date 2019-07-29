const signal_to_class = function (signal) {
  if (signal > 75) {
    return "i-sig-4";
  } else if (signal > 50) {
    return "i-sig-3";
  } else if (signal > 25) {
    return "i-sig-2";
  } else {
    return "i-sig-1";
  }
}

/**
 * Adds or updates an element on one of the ssid list tables.
 * data should contain the following keys:
 *   flags
 *   frequency
 *   signal
 *   ssid
*/
const handle_scanned_ssid = function (data, table_id) {
  var table = document.getElementById(table_id).getElementsByTagName('tbody')[0];
  var row = table.getElementsByClassName(data.ssid)[0];
  if (row) {
    //todo update some stuff here maybe?
    return;
  } else {
    row = table.insertRow();
    row.setAttribute("id", data.ssid);
    row.setAttribute("class", "selectable ssid " + data.ssid);
    row.addEventListener("click", function () {
      var wifiAddElem = document.getElementById("wifi_add");
      wifiAddElem.hidden = false;
      var oldTbody = wifiAddElem.getElementsByTagName('tbody')[0];
      var newTbody = document.createElement('tbody');

      var ssidRow = newTbody.insertRow();
      ssidRow.innerHTML = `
      <label for="input-ssid"> SSID </label>
      <input class="ssidinput" type="text" name="ssid" id="input-ssid">
      `;
      ssidRow.getElementsByClassName("ssidinput")[0].value = data.ssid;

      var frequencyRow = newTbody.insertRow();
      frequencyRow.innerHTML = `
      <label for="input-frequency"> Frequency </label>
      <input class="frequencyinput" type="text" name="frequency" id="input-frequency">
      `;
      frequencyRow.getElementsByClassName("frequencyinput")[0].value = data.frequency;

      var key_mgmtRow = newTbody.insertRow();
      key_mgmtRow.innerHTML = `
      <label for="input-key_mgmt"> Flags </label>
      <input class="key_mgmtinput" type="text" name="key_mgmt" id="input-key_mgmt">
      `;

      if (data.flags.includes("wpa2_psk_ccmp")) {
        key_mgmtRow.getElementsByClassName("key_mgmtinput")[0].value = "wpa_psk";
        var pskRow = newTbody.insertRow();
        pskRow.innerHTML = `
        <label for="input-password"> Passphrase </label>
        <input type="password" name="password" id="input-password">
        `;
      }

      if (data.flags.includes("wpa2_eap_ccmp")) {
        key_mgmtRow.getElementsByClassName("key_mgmtinput")[0].value = "wpa_eap";
        var identityRow = newTbody.insertRow();
        identityRow.innerHTML = `
        <label for="input-identity"> Identity </label>
        <input type="text" name="identity" id="input-identity">
        `;

        var passwordRow = newTbody.insertRow();
        passwordRow.innerHTML = `
        <label for="input-password"> Password </label>
        <input type="password" name="password" id="input-password">
        `;
      }

      var addRow = newTbody.insertRow();
      addRow.innerHTML = `
      <button onclick="addSsid()"> Add </button>
      `;

      oldTbody.parentNode.replaceChild(newTbody, oldTbody);
      // focus on the first input element
      newTbody.children[1].firstElementChild.focus();
    });

    var plusElem = row.getElementsByClassName("plusCell")[0] || row.insertCell(0);
    plusElem.setAttribute("class", "plusCell");
    plusElem.innerHTML = `
    <span>&#10133;</span>
    `;

    var ssidElem = row.getElementsByClassName("ssidCell")[0] || row.insertCell(0);
    ssidElem.setAttribute("class", "ssidCell");
    ssidElem.innerHTML = data.ssid;

    var securityElem = row.getElementsByClassName("securityCell")[0] || row.insertCell(0);
    securityElem.setAttribute("class", "securityCell");

    if (data.flags.length > 0) {
      securityElem.innerHTML = `
      <span>&#128274;</span>
      `;
    } else {
      securityElem.innerHTML = `
      <span></span>
      `;
    }

    var iconsElem = row.getElementsByClassName("iconsCell")[0] || row.insertCell(0);
    iconsElem.setAttribute("class", "iconsCell");
    iconsElem.innerHTML = `
    <svg class="i-sig" x="0px" y="0px" viewBox="0 0 11.26 8">
    <path class="i-sig-w0" d="M6.337,7.247c-0.391-0.391-1.023-0.391-1.414,0l0.708,0.708L6.337,7.247z"></path>
    <g class="i-sig-w">
       <path fill="none" stroke="#000000" stroke-miterlimit="10" d="M7.62,5.966c-1.098-1.098-2.88-1.098-3.977,0"></path>
       <path class="i-sig-wm" fill="none" stroke="#000000" stroke-miterlimit="10" d="M9.31,4.275C7.278,2.244,3.984,2.245,1.952,4.276"></path>
       <path class="i-sig-wo" fill="none" stroke="#000000" stroke-miterlimit="10" d="M10.9,2.684c-2.911-2.911-7.629-2.911-10.54,0"></path>
    </g>
    </svg>
    `;
    iconsElem.children[0].classList.add(signal_to_class(data.signal));
    return;
  }
}

const socket = new WebSocket("ws://" + location.host + "/socket");
socket.onopen = function () {
  console.log("connected");
}

socket.onmessage = function (event) {
  var payload = JSON.parse(event.data);
  switch (payload.type) {
    case "wifi_scan": {
      handle_scanned_ssid(payload.data, "wifi_scan");
      break;
    }
    case "wifi_cfg": {
      handle_scanned_ssid(payload.data, "wifi_cfg");
      break;
    }
    default: {
      console.log("unknown event");
      console.dir(payload.type);
    }
  }
}

const save = function () {
  payload = {
    type: "apply",
    data: {}
  }
  socket.send(JSON.stringify(payload));
}

const addSsid = function () {
  var wifiAddElem = document.getElementById("wifi_add");
  payload = {
    type: "wifi_cfg",
    data: {}
  }
  // get every cell but the "add" button
  for (var i = 0; i < wifiAddElem.children[1].children.length - 1; i++) {
    elem = wifiAddElem.children[1].children[i].children[1];
    payload.data[elem.name] = elem.value;
  }
  socket.send(JSON.stringify(payload));
}
