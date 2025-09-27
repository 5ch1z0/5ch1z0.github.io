const links = {
    "Github": "https://github.com/5ch1z0",
    "TryHackMe": "https://tryhackme.com/p/5CH1Z0"
}


function main() {
    const htmlHeader = document.querySelector("body > div#header");
    const htmlMain = document.querySelector("body > div#main");

    const list = htmlMain.querySelector("> div#list");
    for (const [key, value] of Obhect.entries(links)) {
        const item = document.createElement("div");
        const a = document.createElement("a");
        a.innerText = key;
        a.setAttribute('href', value);

        item.appendChild(a);
        list.appendChild(item);
    }
}


// Load main if DOMContentLoaded
document.addEventListener("DOMContentLoaded", (event) => {
    main();
});
