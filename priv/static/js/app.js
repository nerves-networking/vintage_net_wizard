
/* Stolen from https://www.adriangranados.com/blog/dbm-to-percent-conversion */
const signal_table = {};
signal_table[-1] =	100;
signal_table[-2] =	100;
signal_table[-3] =	100;
signal_table[-4] =	100;
signal_table[-5] =	100;
signal_table[-6] =	100;
signal_table[-7] =	100;
signal_table[-8] =	100;
signal_table[-9] =	100;
signal_table[-10] =	100;
signal_table[-11] =	100;
signal_table[-12] =	100;
signal_table[-13] =	100;
signal_table[-14] =	100;
signal_table[-15] =	100;
signal_table[-16] =	100;
signal_table[-17] =	100;
signal_table[-18] =	100;
signal_table[-19] =	100;
signal_table[-20] =	100;
signal_table[-21] =	99;
signal_table[-22] =	99;
signal_table[-23] =	99;
signal_table[-24] =	98;
signal_table[-25] =	98;
signal_table[-26] =	98;
signal_table[-27] =	97;
signal_table[-28] =	97;
signal_table[-29] =	96;
signal_table[-30] =	96;
signal_table[-31] =	95;
signal_table[-32] =	95;
signal_table[-33] =	94;
signal_table[-34] =	93;
signal_table[-35] =	93;
signal_table[-36] =	92;
signal_table[-37] =	91;
signal_table[-38] =	90;
signal_table[-39] =	90;
signal_table[-40] =	89;
signal_table[-41] =	88;
signal_table[-42] =	87;
signal_table[-43] =	86;
signal_table[-44] =	85;
signal_table[-45] =	84;
signal_table[-46] =	83;
signal_table[-47] =	82;
signal_table[-48] =	81;
signal_table[-49] =	80;
signal_table[-50] =	79;
signal_table[-51] =	78;
signal_table[-52] =	76;
signal_table[-53] =	75;
signal_table[-54] =	74;
signal_table[-55] =	73;
signal_table[-56] =	71;
signal_table[-57] =	70;
signal_table[-58] =	69;
signal_table[-59] =	67;
signal_table[-60] =	66;
signal_table[-61] =	64;
signal_table[-62] =	63;
signal_table[-63] =	61;
signal_table[-64] =	60;
signal_table[-65] =	58;
signal_table[-66] =	56;
signal_table[-67] =	55;
signal_table[-68] =	53;
signal_table[-69] =	51;
signal_table[-70] =	50;
signal_table[-71] =	48;
signal_table[-72] =	46;
signal_table[-73] =	44;
signal_table[-74] =	42;
signal_table[-75] =	40;
signal_table[-76] =	38;
signal_table[-77] =	36;
signal_table[-78] =	34;
signal_table[-79] =	32;
signal_table[-80] =	30;
signal_table[-81] =	28;
signal_table[-82] =	26;
signal_table[-83] =	24;
signal_table[-84] =	22;
signal_table[-85] =	20;
signal_table[-86] =	17;
signal_table[-87] =	15;
signal_table[-88] =	13;
signal_table[-89] =	10;
signal_table[-90] =	8;
signal_table[-91] =	6;
signal_table[-92] =	3;
signal_table[-93] =	1;
signal_table[-94] =	1;
signal_table[-95] =	1;
signal_table[-96] =	1;
signal_table[-97] =	1;
signal_table[-98] =	1;
signal_table[-99] =	1;
signal_table[-100] = 1;

const signal_to_class = function(signal) {
  if(signal_table[signal] > 75) {
    return "i-sig-4";
  } else if(signal_table[signal] > 50) {
    return "i-sig-3";
  } else if(signal_table[signal] > 25) {
    return "i-sig-2";
  } else {
    return "i-sig-1";
  }
}

/**
 * Adds or updates an element on one of the ssid list tables.
 * data should contain the following keys:
 *   bssid
 *   flags
 *   frequency
 *   signal
 *   ssid
 * 
 * also i'm sorry
*/
const handle_scanned_ssid = function(data, table_id) {
  var table = document.getElementById(table_id).getElementsByTagName('tbody')[0];
  var row = table.getElementsByClassName(data.bssid)[0];
  if(row) {
    //todo update some stuff here maybe? 
    return;
  } else {
    row = table.insertRow();
    row.setAttribute("id", data.bssid);
    row.setAttribute("class", "selectable ssid " + data.bssid);
    row.addEventListener("click", function() {
      var wifiAddElem = document.getElementById("wifi_add");
      wifiAddElem.hidden=false;
      var oldTbody = wifiAddElem.getElementsByTagName('tbody')[0];
      var newTbody = document.createElement('tbody');

      var ssidRow = newTbody.insertRow();
      ssidRow.innerHTML = `
      <label for="input-ssid"> SSID </label>
      <input class="ssidinput" type="text" name="ssid" id="input-ssid">
      `;
      ssidRow.getElementsByClassName("ssidinput")[0].value = data.ssid;

      var bssidRow = newTbody.insertRow();
      bssidRow.innerHTML = `
      <label for="input-bssid"> BSSID </label>
      <input class="bssidinput" type="text" name="bssid" id="input-bssid">
      `;
      bssidRow.getElementsByClassName("bssidinput")[0].value = data.bssid;

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
      
      if(data.flags.includes("wpa2_psk_ccmp")) {
        key_mgmtRow.getElementsByClassName("key_mgmtinput")[0].value = "wpa_psk";
        var pskRow = newTbody.insertRow();
        pskRow.innerHTML = `
        <label for="input-psk"> PSK </label>
        <input type="password" name="psk" id="input-psk">
        `;
      }

      if(data.flags.includes("wpa2_eap_ccmp")) {
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
  
    if(data.flags.length > 0) {
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
socket.onopen = function() {
  console.log("connected");
}

socket.onmessage = function(event) {
  var payload = JSON.parse(event.data);
  switch(payload.type) {
    case "wifi_scan": {
      handle_scanned_ssid(payload.data, "wifi_scan");
      break;
    }
    case "wifi_cfg":{
      handle_scanned_ssid(payload.data, "wifi_cfg");
      break;
    }
    default: {
      console.log("unknown event");
      console.dir(payload.type);
    }
  }
}

const save = function() {
  payload = {
    type: "save",
    data: {}
  }
  socket.send(JSON.stringify(payload));
}

const addSsid = function() {
  var wifiAddElem = document.getElementById("wifi_add");
  payload = {
    type: "wifi_cfg",
    data: {}
  }
  // get every cell but the "add" button
  for(var i = 0; i < wifiAddElem.children[1].children.length-1; i++) { 
    elem = wifiAddElem.children[1].children[i].children[1];
    payload.data[elem.name] = elem.value;
  }
  socket.send(JSON.stringify(payload));
}
