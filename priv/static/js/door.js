'use strict';

(() => {
  const doorState = document.querySelector("#door-state");
  const LockState = document.querySelector("#lock-state")
  const LockBtn = document.querySelector("#lock-btn");
  
  getDoorState();
  setInterval(getDoorState, 1000);

  function getDoorState() {
    fetch("/api/v1/door")
      .then((resp) => resp.json())
      .then((state) => {
        doorState.textContent = state.door;
      });
  }

  LockBtn.addEventListener("click", ({ target }) => {
    fetch(`/api/v1/lock`, {
        method: "PUT",
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify({"some" : "param"})
      })

      .then((resp) => resp.json())
      .then(state => {
        console.log("lock-reponse => ", state)
        LockState.textContent = state.lock
      })
    
  });

})()

