with open('resources/views/reportes/show.blade.php', 'r', encoding='utf-8', errors='ignore') as f:
    lines = f.readlines()

new_func = """function editarInformacion(reporteId, pistaId, tituloActual, mensajeActual) {
    Swal.fire({
        title: 'Editar Información',
        html:
            '<input id="swal-input-titulo" class="swal2-input" placeholder="Título" value="' + tituloActual + '">' +
            '<textarea id="swal-input-mensaje" class="swal2-textarea" placeholder="Descripción">' + mensajeActual + '</textarea>',
        focusConfirm: false,
        showCancelButton: true,
        confirmButtonText: 'Guardar cambios',
        cancelButtonText: 'Cancelar',
        preConfirm: () => {
            const titulo = document.getElementById('swal-input-titulo').value;
            const mensaje = document.getElementById('swal-input-mensaje').value;
            if (!titulo || !mensaje) {
                Swal.showValidationMessage('El título y la descripción son obligatorios');
            }
            return { titulo: titulo, mensaje: mensaje }
        }
    }).then((result) => {
        if (result.isConfirmed) {
            const form = document.createElement('form');
            form.method = 'POST';
            form.action = `/reportes/${reporteId}/informacion/${pistaId}/editar`;
            
            const csrfInput = document.createElement('input');
            csrfInput.type = 'hidden';
            csrfInput.name = '_token';
            csrfInput.value = document.querySelector('input[name="_token"]').value;
            
            const methodInput = document.createElement('input');
            methodInput.type = 'hidden';
            methodInput.name = '_method';
            methodInput.value = 'PUT';

            const tituloInput = document.createElement('input');
            tituloInput.type = 'hidden';
            tituloInput.name = 'titulo';
            tituloInput.value = result.value.titulo;
            
            const msgInput = document.createElement('input');
            msgInput.type = 'hidden';
            msgInput.name = 'mensaje';
            msgInput.value = result.value.mensaje;
            
            form.appendChild(csrfInput);
            form.appendChild(methodInput);
            form.appendChild(tituloInput);
            form.appendChild(msgInput);
            document.body.appendChild(form);
            form.submit();
        }
    });
}
"""

lines[1159:1213] = [new_func]

with open('resources/views/reportes/show.blade.php', 'w', encoding='utf-8') as f:
    f.writelines(lines)
