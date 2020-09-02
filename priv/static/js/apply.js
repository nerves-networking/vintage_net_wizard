"use strict";

(() => {
  const state = {
    view: "trying",
    dots: "",
    completeTimer: null,
    targetElem: document.querySelector(".content"),
    configurationStatus: "not_configured",
    completed: false,
    ssid: document.getElementById("ssid").getAttribute("value")
  }

  const relative_path = document.getElementById("relative-path").value;

  function runGetStatus() {
    setTimeout(getStatus, 1000);
  }

  function getStatus() {
    fetch(relative_path + "api/v1/configuration/status")
      .then(resp => resp.json())
      .then(handleStatusResponse)
      .catch(handleNetworkErrorResponse);
  }

  function handleStatusResponse(status) {
    switch (status) {
      case "not_configured":
        state.dots = state.dots + ".";
        render(state);
        break;
      case "good":
        if (!status.completed) {
          state.view = "configurationGood";
          state.configurationStatus = status;
          state.completeTimer = setTimeout(complete, 60000);
          render(state);
        }
        break;
      case "bad":
        state.view = "configurationBad";
        state.configurationStatus = status;
        render(state);
        break;
    }
  }

  function handleNetworkErrorResponse(e) {
    state.dots = state.dots + ".";
    render(state);
  }

  function createCompleteLink({ targetElem, view }) {
    const button = document.createElement("a");
    var btnClass = "btn-primary";
    var btnText = "Complete";

    if (view === "configurationBad") {
      btnClass = "btn-danger";
      btnText = "Complete Without Verification";
    }

    button.classList.add("btn");
    button.classList.add(btnClass);
    button.setAttribute("href", relative_path + "complete");
    button.innerHTML = btnText;

    targetElem.appendChild(button);
  }

  function view({view, dots, ssid}) {
    switch (view) {
      case "trying":
        return [`
        <p>Trying Configuration ${dots}</p>

        <p>VintageNetWizard has disabled Access Point mode and is attempting to connect
        to at least one of the networks in the configuration as verification.</p>

        <p>If this page is present for > 15 seconds, check that you have reconnected to
        the access point "<b>${ssid}</b>"</p>
        `, runGetStatus
        ];
      case "configurationGood":
        return [`
        <p>Configuration okay</p>
        <p>Press "Complete" to exit the wizard and connect to the WiFi.</p>
        <p>The wizard will exit and connect to the WiFi automatically after 60 seconds.</p>
        `, createCompleteLink];
      case "configurationBad":
        return [`
        <p>Looks like there is a problem applying your configuration.</p>
        <p>A few possible reasons are:</p>
        <ul>
          <li>The network password is incorrect</li>
          <li>The network is blocking the connection attempt</li>
          <li>The connection attempt is taking too long and VintageNetWizard is timing out</li>
          <li>None of the configured networks are available</li>
        </ul>
        <p>Check your setup and try configuring again. Or you can also skip verification
        to save the configuration as is.</p>
        <a class="btn btn-primary" href="${relative_path}">Configure</a>
        `, createCompleteLink];
      case "complete":
        return ["Configuration complete", null];
    }
  }

  function render(state) {
    const [innerHTML, action] = view(state);
    state.targetElem.innerHTML = innerHTML;
    
    if (action) {
      action(state);
    }
  }

  fetch(relative_path + "api/v1/apply", {
    method: "POST",
    headers: {
      "Content-Type": "application/json"
    }
  }).then(resp => runGetStatus());
})();
