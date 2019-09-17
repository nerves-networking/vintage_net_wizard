"use strict";

(() => {
  let hasGoodConfiguration = false;
  const statusInterval = setInterval(get_status, 1000);
  const contentDiv = document.querySelector(".content");

  function completeConfiguration() {
    fetch("/api/v1/complete");
  }

  function get_status() {
    timeout(1000, fetch("/api/v1/configuration/status"))
      .then((resp) => resp.json())
      .then(body => {
        switch (body) {
          case "not_configured":
            contentDiv.innerHTML += ".";
            break;
          case "good":
            if (hasGoodConfiguration) {
              break;
            } else {
              clearInterval(statusInterval);
              contentDiv.innerHTML =
                `
                <p>Connected successfully</p>
                <p>Press Complete to exit the wizard and connect to the access point again. The wizard will exit automatically after 60 seconds.</p>
                <a class="btn btn-primary" href="/complete">Next</a>
                `
              setTimeout(completeConfiguration, 60000);
              hasGoodConfiguration = true;
              break;
            }
          case "bad":
            clearInterval(statusInterval);
            console.log("boo");
            break;
        }
      })
      .catch(error => contentDiv.innerHTML += ".");
  }

  function timeout(ms, promise) {
    return new Promise((resolve, reject) => {
      const timeoutId = setTimeout(() => {
        reject(new Error("promise timeout"))
      }, ms);
      promise.then(
        (res) => {
          clearTimeout(timeoutId);
          resolve(res);
        },
        (err) => {
          clearTimeout(timeoutId);
          reject(err);
        }
      );
    })
  }
})();
