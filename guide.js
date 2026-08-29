// 복사 버튼 — 7장 공용
document.querySelectorAll('.copy-btn').forEach(function (btn) {
  btn.addEventListener('click', function () {
    var pre = btn.closest('.try').querySelector('pre');
    navigator.clipboard.writeText(pre.innerText).then(function () {
      var old = btn.textContent;
      btn.textContent = '복사됨 ✓';
      btn.classList.add('ok');
      setTimeout(function () { btn.textContent = old; btn.classList.remove('ok'); }, 1400);
    });
  });
});
