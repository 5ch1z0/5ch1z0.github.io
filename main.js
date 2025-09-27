function main() {
    const htmlHeader = document.querySelector("body > div#header");
    const htmlMain = document.querySelector("body > div#main");

    let list_item = document.createElement("div");
    list_item.innerText = "list item";
    htmlMain.appendChild(list_item);
}

document.addEventListener("DOMContentLoaded", (event) => {
    main();
});
