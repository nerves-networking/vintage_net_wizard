'use strict';

(() => {
  const accessPointsTable = document.querySelector(".access-points-table");
  const body = accessPointsTable.tBodies.item(0);
  getAccessPoints();
  setInterval(getAccessPoints, 5000);

  function getAccessPoints() {
    fetch("/api/v1/access_points")
      .then((resp) => resp.json())
      .then((accessPoints) => {
        body.innerHTML = "";
        for (let i = 0; i < accessPoints.length; i++) {
          const newRow = body.insertRow();
          buildAccessPointRow(newRow, accessPoints[i]);
          addSecurityData(newRow, accessPoints[i]);
          addSSIDData(newRow, accessPoints[i]);
          newRow.classList.add("network");

          if (newRow.dataset.security === "none") {
            attachClickEvent(newRow, "addConfig");
          } else {
            attachClickEvent(newRow, "requirePassword");
          }
        }
      });
  }

  function buildAccessPointRow(row, accessPoint) {
    const ssidElem = buildSSIDTableData(accessPoint);
    const securityElem = buildSecurityTableData(accessPoint);
    const signalElem = buildSignalTableData(accessPoint);

    row.appendChild(ssidElem);
    row.appendChild(securityElem);
    row.appendChild(signalElem);
  }

  function buildSSIDTableData({ ssid }) {
    const tdElem = document.createElement("td");
    const ssidText= document.createTextNode(ssid);

    tdElem.appendChild(ssidText);
    tdElem.classList.add("font-weight-bold");

    return tdElem
  }

  function buildSecurityTableData({ flags }) {
    if (flags.includes("none") || flags.length === 0) {
      return document.createElement("td");
    } else {
      const tdElem = document.createElement("td");
      const securityText = document.createTextNode(getSecurityDisplayName(flags));
      tdElem.appendChild(securityText);

      return tdElem;
    }
  }

  function addSecurityData(row, { flags }) {
    if (isWPAPersonal(flags)) {
      row.setAttribute("data-security", "wpa");
    } else if (flags.includes("none") || flags.length === 0) {
      row.setAttribute("data-security", "none");
    } else {
      console.warn("Unsupported security");
    }
  }

  function addSSIDData(row, { ssid }) {
    row.setAttribute("data-ssid", ssid);
  }

  function buildSignalTableData({ signal_percent, signal_dbm }) {
    const tdElem = document.createElement("td");
    const textNode = document.createTextNode(`${signal_percent}%(${signal_dbm} dBm)`);

    tdElem.appendChild(textNode);

    return tdElem;
  }

  function getSecurityDisplayName(flags) {
    if (isWPAPersonal(flags)) {
      return "WPA2 Personal";
    } else if (isWPAEnterprise(flags)) {
      return "WPA Enterprise";
    } else {
      console.warn("Unsupported security");
      return "Not Supported"
    }
  }

  function attachClickEvent(networkTR, type) {
    networkTR.addEventListener("click", ({ target }) => {
      if (type === "addConfig") {
        fetch("/api/v1/configurations", {
          method: "PUT",
          headers: {
            "Content-Type": "application/json"
          },
          body: JSON.stringify([{
            ssid: target.parentElement.dataset.ssid,
            password: "",
            key_mgmt: "none"
          }])
        })
        .then(resp => {
          window.location.href = "/";
        })
      } else {
        window.location.href = "/ssid/" + encodeURI(target.parentElement.dataset.ssid);
      }
    });
  }

  function isWPAPersonal(flags) {
    const supportedPersonalWPAFlags = [
      "wpa2_psk_ccmp",
      "wpa2_psk_ccmp_tkip",
      "wpa_psk_ccmp_tkip"
    ];

    return flags.some(flag => supportedPersonalWPAFlags.includes(flag));
  }

  function isWPAEnterprise(flags) {
    return flags.includes("wpa2_eap_ccmp");
  }
})()

