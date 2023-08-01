'use strict';

(() => {
  //const cam0 = document.querySelector("#cam0");
  //const cam1 = document.querySelector("#cam1");
  //const cam2 = document.querySelector("#cam2");
  const doorState = document.querySelector("#door-state");
  const LockState = document.querySelector("#lock-state")
  const LockBtn = document.querySelector("#lock-btn");
  
  getDoorState();
  setInterval(getDoorState, 1000);

  getLockState();
  setInterval(getLockState, 1000);

  initStream();
  
  setTimeout(() => changeVideo("0", 1), 1500)
  
  changeVideo(() => changeVideo("1", 1), 1500)
  
  changeVideo(() => changeVideo("2", 1), 1500)
  
  function initStream() {
    fetch("/api/v1/init_cams")
      .then((resp) => resp.json())
      .then((state) => {
      });
  }

  function stopStream() {
    fetch("/api/v1/stop_cams")
      .then((resp) => resp.json())
      .then((state) => {
      });
  }

  window.addEventListener("beforeunload", function (e) {
    stopStream()
    return                             //Webkit, Safari, Chrome
    });

  window.addEventListener("onunload", function (e) {
    stopStream()
    return                             //Webkit, Safari, Chrome
    });

  async function changeVideo(cam_index, index){
    const cam = document.querySelector(`#cam${cam_index}`);
    
    const format_index = index.toString().padStart(4, '0');

    cam.setAttribute('src', `/root/cam${cam_index}/frame${format_index}.jpg`)
   
    await sleep(1000)

    changeVideo(cam_index, index+1)
  }

  function sleep(ms){
    return new Promise(resolve => setTimeout(resolve, ms));
  };

  function getDoorState() {
    fetch("/api/v1/door")
      .then((resp) => resp.json())
      .then((state) => {
        doorState.textContent = state.door;
      });
  }

  function getLockState() {
    fetch("/api/v1/status_lock")
      .then((resp) => resp.json())
      .then((state) => {
        LockState.textContent = state.lock;
      });
  }

  LockBtn.addEventListener("click", ({ target }) => {
    disableBtn(LockBtn, true);
    fetch("/api/v1/lock", {
        method: "PUT",
        headers: {
          "Content-Type": "application/json"
        },
        body: ""
      })
      setTimeout(() => disableBtn(LockBtn, false), 1000);
  });

  function disableBtn(btn, disabled){
    btn.disabled = disabled; 
   }

})()

