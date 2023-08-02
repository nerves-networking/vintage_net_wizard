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

  setTimeout(() => initStream(), 1000)

  setTimeout(() => changeVideo("0", 1), 2000)

  setTimeout(() => changeVideo("1", 1), 2000)
  
  setTimeout(() => changeVideo("2", 1), 2000)

  async function fetchBinaryData(url, data) {
    const response = await fetch(url, {
      method: 'POST',
      body: JSON.stringify(data),
      headers: {
        'Content-Type': 'application/json'
      }
    });
  
    if (!response.ok) {
      throw new Error('Error al obtener el binary.');
    }
  
    return response.arrayBuffer();
  }

  function arrayBufferToBase64(buffer) {
    let binary = '';
    const bytes = new Uint8Array(buffer);
    const len = bytes.byteLength;
    for (let i = 0; i < len; i++) {
      binary += String.fromCharCode(bytes[i]);
    }
    return btoa(binary);
  }

  function setcam(cam, binaryData) {
    const base64Data = arrayBufferToBase64(binaryData);
    cam.src = 'data:image/jpeg;base64,' + base64Data;
  }
  
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

    //cam.setAttribute('src', `/root/cam${cam_index}/frame${format_index}.jpg`)
    
    fetchBinaryData("/api/v1/cam", {cam_index: cam_index, format_index: format_index})
  .then((binaryData) => {
    setcam(cam, binaryData);
  })
  .catch((error) => {
    console.error('Error:', error);
  });
   
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

