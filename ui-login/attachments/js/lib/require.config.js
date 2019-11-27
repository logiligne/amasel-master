var jam = {
    "packages": [
        {
            "name": "jquery",
            "location": "lib/jquery",
            "main": "dist/jquery.js"
        },
        {
            "name": "modernizr",
            "location": "lib/modernizr"
        }
    ],
    "version": "0.2.13",
    "shim": {}
};

if (typeof require !== "undefined" && require.config) {
    require.config({
    "packages": [
        {
            "name": "jquery",
            "location": "lib/jquery",
            "main": "dist/jquery.js"
        },
        {
            "name": "modernizr",
            "location": "lib/modernizr"
        }
    ],
    "shim": {}
});
}
else {
    var require = {
    "packages": [
        {
            "name": "jquery",
            "location": "lib/jquery",
            "main": "dist/jquery.js"
        },
        {
            "name": "modernizr",
            "location": "lib/modernizr"
        }
    ],
    "shim": {}
};
}

if (typeof exports !== "undefined" && typeof module !== "undefined") {
    module.exports = jam;
}