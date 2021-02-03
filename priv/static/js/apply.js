"use strict";

function applyConfiguration(title, button_color) {
  const state = {
    view: "trying",
    dots: "",
    completeTimer: null,
    targetElem: document.querySelector(".content"),
    configurationStatus: "not_configured",
    completed: false,
    ssid: document.getElementById("ssid").getAttribute("value"),
    title: title
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

  function createCompleteLink({ targetElem, view }) {
    const button = document.createElement("button");
    var btnClass = "btn-primary";
    var btnText = "Complete";

    if (view === "configurationBad") {
      btnClass = "btn-danger";
      btnText = "Complete Without Verification";
    }

    if (view != "configurationBad") {
      button.style.backgroundColor = button_color;
    }

    button.classList.add("btn");
    button.classList.add(btnClass);
    button.addEventListener("click", handleCompleteClick);
    button.innerHTML = btnText;

    targetElem.appendChild(button);
  }

  function handleCompleteClick(e) {
    if (state.completeTimer) {
      clearTimeout(state.completeTimer);
      state.completeTimer = null;
    }
    complete();
  }

  function view({ view, title, dots, ssid }) {
    switch (view) {
      case "trying":
        return [`
        <p>Please wait while the ${title} verifies your configuration.</p>

        <p>${dots}</p>

        <p>If this page doesn't update in 15-30 seconds, check that you're connected to
        the access point named "<b>${ssid}</b>"</p>
        `, runGetStatus
        ];
      case "configurationGood":
        return [`
        <p>Success!</p>

        <p>Press "Complete" to exit the wizard and connect back to your previous network.</p>
        <p>Exiting automatically after 60 seconds.</p>
        `, createCompleteLink];
      case "configurationBad":
        return [`
        <p>Failed to connect.</p>

        <p>Try checking the following:</p>
        <ul>
          <li>All WiFi passwords are correct</li>
          <li>At least one network is in range</li>
          <li>Whether your network administrator requires additional steps for granting access to the WiFi network</li>
        </ul>

        <p>Please check your setup and try again or skip verification.</p>
        <a class="btn btn-primary" href="/">Configure</a>
        `, createCompleteLink];
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
}
