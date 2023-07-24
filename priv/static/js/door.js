'use strict';

(() => {
  const cam0 = document.querySelector("#cam0");
  const cam1 = document.querySelector("#cam1");
  const cam2 = document.querySelector("#cam2");
  const doorState = document.querySelector("#door-state");
  const LockState = document.querySelector("#lock-state")
  const LockBtn = document.querySelector("#lock-btn");
  
  getDoorState();
  setInterval(getDoorState, 1000);

  getLockState();
  setInterval(getLockState, 1000);

  getCams();
  setInterval(getCams, 4000);


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

  function setcam0(binaryData) {
    const base64Data = arrayBufferToBase64(binaryData);
    cam0.src = 'data:image/jpeg;base64,' + base64Data;
  }

  function setcam1(binaryData) {
    const base64Data = arrayBufferToBase64(binaryData);
    cam1.src = 'data:image/jpeg;base64,' + base64Data;
  }

  function setcam2(binaryData) {
    const base64Data = arrayBufferToBase64(binaryData);
    cam2.src = 'data:image/jpeg;base64,' + base64Data;
  }

  function getCams() {

    fetch("/api/v1/cams")
      .then((resp) => resp.json())
      .then((state) => {
      });

    fetchBinaryData("/api/v1/cam1", "")
  .then((binaryData) => {
    setcam0(binaryData);
  })
  .catch((error) => {
    console.error('Error:', error);
  });

    fetchBinaryData("/api/v1/cam2", "")
      .then((binaryData) => {
        setcam1(binaryData);
      })
      .catch((error) => {
        console.error('Error:', error);
      });
 
  
    fetchBinaryData("/api/v1/cam3", "")
      .then((binaryData) => {
        setcam2(binaryData);
      })
      .catch((error) => {
        console.error('Error:', error);
      });

  }

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

