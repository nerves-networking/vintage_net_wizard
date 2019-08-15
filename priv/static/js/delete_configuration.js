'use strict';

const configurations = () => {
  const deleteConfigs = document.querySelectorAll(".configuration-delete");

  for (let i = 0; i < deleteConfigs.length; i++) {
    deleteConfigs[i].addEventListener("click", (e) => {
      const td = e.currentTarget.parentElement;
      fetch("/api/v1/configurations", {
        method: "PUT",
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify([])
       })
       .then(resp => {
         td.parentElement.removeChild(td);
       })
    }, { once: true});
  }
}

configurations();

