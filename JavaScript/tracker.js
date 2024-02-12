function miriads_trackInputChanges() {
    console.log('[MIRIADS] - Enumerating all input fields...');

    // Получаем все элементы ввода на странице
    var inputFields = document.querySelectorAll('input');

    // Для каждого поля ввода подписываемся на событие изменения
    inputFields.forEach(function(input) {
        input.addEventListener('input', function(event) {
            // Получаем значение поля ввода, которое изменилось
            var value = event.target.value;
            // Действие при изменении значения (можно заменить на другое действие)
            console.log('Updated input field:', value);
        });
    });
}

console.log('[MIRIADS] - Tracking script loaded. Registering for DOM loaded...');

// Вызываем функцию отслеживания изменений при загрузке страницы
document.addEventListener('DOMContentLoaded', function() {
    console.log('[MIRIADS] - Page DOM loaded. Starting tracking...');

    miriads_trackInputChanges();
});