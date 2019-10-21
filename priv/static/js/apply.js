"use strict";

(() => {
  const state = {
    view: "trying",
    dots: "",
    completeTimer: null,
    targetElem: document.querySelector(".content"),
    configurationStatus: "not_configured",
    completed: false
  }

  function runGetStatus() {
    setTimeout(getStatus, 1000);
  }

  function getStatus() {
    fetch("/api/v1/configuration/status")
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

  function createCompleteLink({ targetElem }) {
    const button = document.createElement("button");
    button.classList.add("btn");
    button.classList.add("btn-primary");
    button.addEventListener("click", handleCompleteClick); 
    button.innerHTML = "Complete";

    targetElem.appendChild(button);
  }

  function handleCompleteClick(e) {
    if (state.completeTimer) {
      clearTimeout(state.completeTimer);
      state.completeTimer = null;
    }
    complete();
  }

  function view({view, dots}) {
    switch (view) {
      case "trying":
        return ["Trying configuration" + dots, runGetStatus];
      case "configurationGood":
        return [`
        <p>Configuration okay</p>
        <p>Press "Complete" to exit the wizard and connect to the WiFi.</p>
        <p>The wizard will exit and connect to the WiFi automatically after 60 seconds.</p>
        `, createCompleteLink];
      case "configurationBad":
        return [`
        <p>Looks like there is a problem with your configuration.</p>
        <p>Please ensure that your password(s) are correct and/or the
        network you are trying to connect to is available.</p>
        <a class="btn btn-primary" href="/">Configure</a>
        `, null];
      case "complete":
        return ["Configuration complete", null];
    }
  }

  function complete() {
    fetch("/api/v1/complete")
      .then(resp => {
        state.view = "complete";
        render(state);
      });
  }

  function render(state) {
    const [innerHTML, action] = view(state);
    state.targetElem.innerHTML = innerHTML;
    
    if (action) {
      action(state);
    }
  }

  fetch("/api/v1/apply", {
    method: "POST",
    headers: {
      "Content-Type": "application/json"
    }
  }).then(resp => runGetStatus());
})();
