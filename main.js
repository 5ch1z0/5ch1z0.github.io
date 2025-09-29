const links = {
    "Github": "https://github.com/5ch1z0",
    "TryHackMe": "https://tryhackme.com/p/5CH1Z0",
    "HackTheBox": "https://app.hackthebox.eu/profile/5ch1z0one",
    "LinkedIn": "https://www.linkedin.com/in/martan-van-verseveld/",
    "Discord": "https://discord.com/users/5ch1z0",
    "HackerOne": "https://hackerone.com/5ch1z0"
}

const settings = {
    'lowercase': false
}


function main() {
    const htmlHeader = document.querySelector("body > div#header");
    const htmlMain = document.querySelector("body > div#main");

    const list = htmlMain.querySelector("div#list");
    for (const [key, value] of Object.entries(links)) {
        const item = document.createElement("div");
        const a = document.createElement("a");
        a.innerText = settings.lowercase ? key.toLowerCase() : key;
        a.classList.add("list-item");
        a.setAttribute('href', value);
        a.setAttribute('target', "_blank");
        a.setAttribute('rel', "noopener noreferrer");

        item.appendChild(a);
        list.appendChild(item);
    }
}


// Load main if DOMContentLoaded
document.addEventListener("DOMContentLoaded", (event) => {
    main();
});
