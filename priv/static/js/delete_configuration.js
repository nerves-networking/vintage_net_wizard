'use strict';

const configurations = () => {
  const deleteConfigs = document.querySelectorAll(".configuration-delete");
  const relative_path = document.getElementById("relative-path").value;

  for (let i = 0; i < deleteConfigs.length; i++) {
    deleteConfigs[i].addEventListener("click", (e) => {
      const td = e.currentTarget.parentElement;
      const ssid = td.dataset.ssid;
      fetch(`${relative_path}api/v1/${ssid}/configuration`, {
        method: "DELETE",
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify({})
       })
       .then(resp => {
         td.parentElement.removeChild(td);
       })
    }, { once: true});
  }
}

configurations();

