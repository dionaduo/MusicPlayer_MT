// let lrc = `[00:00.00]湘女多情 - 周杰伦\n[00:07.00]词：方文山\n[00:12.00]曲：周杰伦\n[00:17.00]湘女多情 暮色已落地\n[00:25.00]檐下满园鸟啼\n[00:28.00]你却倚窗锁眉不语\n[00:32.00]锣腔唱起 一出花鼓戏\n[00:39.00]惆怅又添几许\n[00:42.00]是谁离去你不愿提\n[00:45.00]落花雨不停 湘女总是多情\n[00:49.00]凋谢却将爱 铺满了地\n[00:53.00]你说你愿意 静静留在原地\n[00:56.00]只为可能的 再次相遇\n[00:59.00]秋不舍花季 湘女总是多情\n[01:04.00]在梦中浓郁 所有秘密\n[01:07.00]微笑等风起 你说缘会如期\n[01:11.00]等盛开的菊 带来消息\n[01:30.00]湘女多情 暮色已落地\n[01:37.00]檐下满园鸟啼\n[01:40.00]你却倚窗锁眉不语\n[01:45.00]锣腔唱起 一出花鼓戏\n[01:52.00]惆怅又添几许\n[01:55.00]是谁离去你不愿提\n[01:58.00]落花雨不停 湘女总是多情\n[02:02.00]凋谢却将爱 铺满了地\n[02:05.00]你说你愿意 静静留在原地\n[02:09.00]只为可能的 再次相遇\n[02:12.00]秋不舍花季 湘女总是多情\n[02:16.00]在梦中浓郁 所有秘密\n[02:20.00]微笑等风起 你说缘会如期\n[02:24.00]等盛开的菊 带来消息\n[02:28.00]纷飞细雨 料峭春意\n[02:30.00]别离已美成了回忆\n[02:32.00]含泪的你永不老去\n[02:33.00]停格了那过去\n[02:35.00]我跟苍天下了盘棋\n[02:37.00]你愁绪在酝酿秘密\n[02:39.00]连感伤都轻如柳絮\n[02:41.00]落花雨不停 湘女总是多情\n[02:45.00]凋谢却将爱 铺满了地\n[02:49.00]你说你愿意 静静留在原地\n[02:53.00]只为可能的 再次相遇\n[02:56.00]秋不舍花季 湘女总是多情\n[03:00.00]在梦中浓郁 所有秘密\n[03:04.00]落泪如琴音 碎了一地谁听\n[03:07.00]繁华归浮云 你归爱情\n[03:11.00]娘子 娘子却依旧每日 折一枝杨柳\n[03:14.00]你在那里\n[03:15.00]在小村外的溪边河口 默默等着我\n[03:19.00]娘子依旧每日折一枝杨柳 你在那里\n[03:22.00]在小村外的溪边 默默等着 娘子\n[03:26.00]啦～啦～啦～湘女多情\n[03:40.00]啦～啦～啦～湘女多情\n"
// `;

let lrc;
let url =
    "https://www.qqmp3.vip/api/kw.php?rid=125380&type=json&level=exhigh&lrc=true";
const oBtns = document.querySelectorAll("button");
const oAudio = document.querySelector("audio");
const oDiv = document.querySelector("#txt");
fetch(url, { method: "get" })
    .then((res) => res.json())
    .then((res) => {
        let {
            data: { url, lrc },
        } = res;
        loadData(url, lrc);
    });

function converTime(n) {
    let a = parseInt(n / 60)
        .toString()
        .padStart(2, 0);
    let b = parseInt(n % 60)
        .toString()
        .padStart(2, 0);
    return `${a}:${b}`;
}

//如果正在播放就会时时触发timeupdate
oAudio.addEventListener("timeupdate", () => {
    // console.log("timeupdate");
    console.log(converTime(oAudio.currentTime), converTime(oAudio.duration));
    if (oLRC[converTime(oAudio.currentTime) + ".00"]) {
        oDiv.innerHTML = oLRC[converTime(oAudio.currentTime) + ".00"];
    }
});

function loadData(url, lrc = "") {
    oAudio.src = url;
    window.lrc = lrc;
    console.dir(window.lrc);
}

let oLRC = {};
//播放功能
oBtns[0].onclick = () => {
    oAudio.play();
    let arr = window.lrc.split(/\n/);
    arr.forEach((item) => {
        var arr1 = item.replace("[", "").split("]");
        console.log(arr1[0], arr1[1]);
        oLRC[arr1[0]] = arr1[1];
    });
};

//暂停
oBtns[1].onclick = () => {
    oAudio.pause();
};

oBtns[2].onclick = () => {
    if (oAudio.volume >= 1) {
        return;
    }
    let num = parseInt(oAudio.volume * 10);
    num++;
    num = num / 10;
    // console.log((num)/10);
    oAudio.volume = num;
};
oBtns[3].onclick = () => {
    console.log(oAudio.volume);

    if (oAudio.volume <= 0.1) {
        return;
    }
    let num = parseInt(oAudio.volume * 10);
    num--;
    num = num / 10;
    // console.log((num)/10);
    oAudio.volume = num;
};
let volumeNum = 0;
oBtns[4].onclick = () => {
    if (oAudio.volume != 0) {
        volumeNum = oAudio.volume;
        oAudio.volume = 0;
    } else {
        oAudio.volume = volumeNum;
    }
};


// volume 声音大小
// pause 暂停
// currentTime 当前时间, 
// oAudio.duration 歌曲的从时间
// timeupdate 正在播放就会触发改事件
