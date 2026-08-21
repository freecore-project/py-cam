# cython: language_level=3, c_string_type=unicode, c_string_encoding=default
# Copyright (c) 2015 iXsystems, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#

from libc.stdint cimport *


cdef extern from "sys/endian.h":
    uint16_t bswap16(uint16_t int16)
    uint32_t bswap32(uint32_t int32)
    uint32_t htole32(uint32_t host32)
    uint64_t htole64(uint64_t host64)


cdef extern from "fcntl.h":
    enum:
        O_RDWR


cdef extern from "camlib.h" nogil:
    ctypedef int path_id_t
    ctypedef int lun_id_t
    ctypedef int target_id_t

    enum:
        MAXPATHLEN
        DEV_IDLEN
        SIM_IDLEN

    cdef struct cam_device:
        char device_path[MAXPATHLEN + 1]
        char given_dev_name[DEV_IDLEN + 1]
        uint32_t given_unit_number
        char device_name[DEV_IDLEN + 1]
        uint32_t dev_unit_num
        char sim_name[SIM_IDLEN + 1]
        uint32_t sim_unit_number
        uint32_t bus_id
        lun_id_t target_lun
        target_id_t target_id
        path_id_t path_id
        uint16_t pd_type
        uint8_t serial_num[252]
        uint8_t serial_num_len
        uint8_t sync_period
        uint8_t sync_offset
        uint8_t bus_width
        int fd

    cdef cam_device* cam_open_device(char* path, int flags)
    cdef void cam_close_device(cam_device* dev)
    cdef ccb *cam_getccb(cam_device* dev)
    cdef int cam_send_ccb(cam_device* dev, ccb* ccb)


cdef extern from "cam/ata/ata_all.h" nogil:

    cdef struct ata_cmd:
        uint8_t flags
        uint8_t command
        uint8_t features
        uint8_t lba_low
        uint8_t lba_mid
        uint8_t lba_high
        uint8_t device
        uint8_t lba_low_exp
        uint8_t lba_mid_exp
        uint8_t lba_high_exp
        uint8_t features_exp
        uint8_t sector_count
        uint8_t sector_count_exp
        uint8_t control

    cdef struct ata_res:
        uint8_t flags
        uint8_t status
        uint8_t error

    extern void ata_28bit_cmd(ccb_ataio *, uint8_t, uint8_t, uint32_t, uint8_t)
    extern void ata_48bit_cmd(ccb_ataio *, uint8_t, uint16_t, uint64_t, uint16_t)


cdef extern from "cam/cam_ccb.h" nogil:

    ctypedef enum xpt_opcode:
        XPT_FC_QUEUED = 0x100
        XPT_FC_DEV_QUEUED = 0x800 | XPT_FC_QUEUED
        XPT_ATA_IO = 0x18

    cdef struct ccb_hdr:
        uint32_t retry_count
        void (*cbfcnp)(void *, void*)
        uint32_t status
        uint32_t flags
        uint32_t xflags
        xpt_opcode func_code
        uint32_t timeout

    ctypedef enum ccb_flags:
        CAM_DIR_IN = 0x00000040
        CAM_DIR_OUT = 0x00000080
        CAM_PASS_ERR_RECOVER = 0x00010000

    cdef struct ccb_scsiio:
        uint32_t dxfer_len
        uint8_t sense_len
        uint8_t cdb_len
        uint8_t scsi_status
        uint8_t sense_resid
        uint32_t resid

    cdef struct ccb_ataio:
        ccb_hdr ccb_h
        void *next_ccb
        ata_cmd cmd
        ata_res res
        uint8_t *data_ptr
        uint32_t dxfer_len
        uint32_t resid
        uint8_t ata_flags
        uint8_t icc
        uint32_t aux
        uint32_t unused

    cdef union ccb:
        ccb_hdr ccb_h
        ccb_scsiio csio
        ccb_ataio ataio


cdef extern from "cam/scsi/scsi_all.h" nogil:
    ctypedef void * ccb_callback_t

    enum:
        SSD_FULL_SIZE
        SSD_MIN_SIZE
        SSD_EXTRA_MAX

    enum:
        SCSI_RW_READ
        SCSI_RW_WRITE
        SCSI_RW_DIRMASK
        SCSI_RW_BIO

    enum:
        SPRI_RK
        SPRI_RR
        SPRI_RC
        SPRI_RS
        SPRI_MAX_LEN

    enum:
        SPRT_WE
        SPRT_EA
        SPRT_WERO
        SPRT_EARO
        SPRT_WEAR
        SPRT_EAAR

    enum:
        SPRO_REGISTER
        SPRO_RESERVE
        SPRO_RELEASE
        SPRO_CLEAR
        SPRO_PREEMPT
        SPRO_PRE_ABO
        SPRO_REG_IGNO
        SPRO_REG_MOVE
        SPRO_REPL_LOST_RES
        SPRO_ACTION_MASK

    enum:
        SPR_SCOPE_MASK
        SPR_SCOPE_SHIFT
        SPR_LU_SCOPE
        SPR_EXTENT_SCOPE
        SPR_ELEMENT_SCOPE
        SPR_TYPE_MASK
        SPR_TYPE_RD_SHARED
        SPR_TYPE_WR_EX
        SPR_TYPE_RD_EX
        SPR_TYPE_EX_AC
        SPR_TYPE_SHARED
        SPR_TYPE_WR_EX_RO
        SPR_TYPE_EX_AC_RO
        SPR_TYPE_WR_EX_AR
        SPR_TYPE_EX_AC_AR

    cdef struct scsi_read_capacity_data:
        uint8_t addr[4]
        uint8_t length[4]

    cdef struct scsi_report_luns_data:
        uint8_t length[4]
        uint8_t reserved[4]

    cdef struct scsi_sense_data:
        uint8_t error_code
        uint8_t sense_buf[SSD_FULL_SIZE - 1]

    cdef struct scsi_per_res_in:
        uint8_t opcode
        uint8_t action
        uint8_t reserved[5]
        uint8_t length[2]
        uint8_t control

    cdef struct scsi_per_res_in_header:
        uint8_t generation[4]
        uint8_t length[4]

    cdef struct scsi_per_res_key:
        uint8_t key[8]

    cdef struct scsi_per_res_in_keys:
        scsi_per_res_in_header header
        scsi_per_res_key keys[0]

    cdef struct scsi_per_res_in_rsrv_data:
        uint8_t reservation[8]
        uint8_t scope_addr[4]
        uint8_t reserved
        uint8_t scopetype
        uint8_t extent_length[2]

    cdef struct scsi_per_res_in_rsrv:
        scsi_per_res_in_header header
        scsi_per_res_in_rsrv_data data

    cdef struct scsi_per_res_out:
        uint8_t opcode
        uint8_t action
        uint8_t scope_type
        uint8_t reserved[2]
        uint8_t length[4]
        uint8_t control

    cdef struct scsi_per_res_out_parms:
        scsi_per_res_key res_key
        uint8_t serv_act_res_key[8]
        uint8_t scope_spec_address[4]
        uint8_t flags
        uint8_t reserved1
        uint8_t extent_length[2]
        uint8_t transport_id_list[0]

    void scsi_ulto2b(uint32_t val, uint8_t *bytes)
    void scsi_ulto3b(uint32_t val, uint8_t *bytes)
    void scsi_ulto4b(uint32_t val, uint8_t *bytes)
    void scsi_u64to8b(uint64_t val, uint8_t *bytes)
    uint32_t scsi_2btoul(const uint8_t *bytes)
    uint32_t scsi_3btoul(const uint8_t *bytes)
    uint32_t scsi_4btoul(const uint8_t *bytes)
    uint64_t scsi_8btou64(const uint8_t *bytes)

    void scsi_test_unit_ready(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        uint8_t sense_len,
        uint32_t timeout
    )

    void scsi_request_sense(
        ccb_scsiio *csio, uint32_t retries,
        ccb_callback_t *cbfcnp,
        void *data_ptr,
        uint8_t dxfer_len,
        uint8_t tag_action,
        uint8_t sense_len,
        uint32_t timeout
    )

    void scsi_inquiry(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        uint8_t *inq_buf,
        uint32_t inq_len,
        int evpd,
        uint8_t page_code,
        uint8_t sense_len,
        uint32_t timeout
    )

    void scsi_mode_sense(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        int dbd,
        uint8_t page_code,
        uint8_t page,
        uint8_t *param_buf,
        uint32_t param_len,
        uint8_t sense_len,
        uint32_t timeout
    )

    void scsi_mode_sense_len(
        ccb_scsiio *csio, uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        int dbd,
        uint8_t page_code,
        uint8_t page,
        uint8_t *param_buf,
        uint32_t param_len,
        int minimum_cmd_size,
        uint8_t sense_len,
        uint32_t timeout
    )

    void scsi_mode_select(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        int scsi_page_fmt,
        int save_pages,
        uint8_t *param_buf,
        uint32_t param_len,
        uint8_t sense_len,
        uint32_t timeout
    )

    void scsi_mode_select_len(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        int scsi_page_fmt,
        int save_pages,
        uint8_t *param_buf,
        uint32_t param_len,
        int minimum_cmd_size,
        uint8_t sense_len,
        uint32_t timeout
    )

    void scsi_log_sense(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        uint8_t page_code,
        uint8_t page,
        int save_pages,
        int ppc,
        uint32_t paramptr,
        uint8_t *param_buf,
        uint32_t param_len,
        uint8_t sense_len,
        uint32_t timeout
    )

    void scsi_log_select(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        uint8_t page_code,
        int save_pages,
        int pc_reset,
        uint8_t *param_buf,
        uint32_t param_len,
        uint8_t sense_len,
        uint32_t timeout
    )

    void scsi_prevent(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        uint8_t action,
        uint8_t sense_len,
        uint32_t timeout
    )

    void scsi_read_capacity(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        scsi_read_capacity_data *,
        uint8_t sense_len,
        uint32_t timeout
    )

    void scsi_read_capacity_16(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        uint64_t lba,
        int reladr,
        int pmi,
        uint8_t *rcap_buf,
        int rcap_buf_len,
        uint8_t sense_len,
        uint32_t timeout
    )

    void scsi_report_luns(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        uint8_t select_report,
        scsi_report_luns_data *rpl_buf,
        uint32_t alloc_len,
        uint8_t sense_len,
        uint32_t timeout
    )

    void scsi_report_target_group(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        uint8_t pdf,
        void *buf,
        uint32_t alloc_len,
        uint8_t sense_len,
        uint32_t timeout
    )

    void scsi_set_target_group(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        void *buf,
        uint32_t alloc_len,
        uint8_t sense_len,
        uint32_t timeout
    )

    void scsi_synchronize_cache(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        uint32_t begin_lba,
        uint16_t lb_count,
        uint8_t sense_len,
        uint32_t timeout
    )

    void scsi_receive_diagnostic_results(
        ccb_scsiio *csio, uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        int pcv,
        uint8_t page_code,
        uint8_t *data_ptr,
        uint16_t allocation_length,
        uint8_t sense_len,
        uint32_t timeout
    )

    void scsi_send_diagnostic(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        int unit_offline,
        int device_offline,
        int self_test,
        int page_format,
        int self_test_code,
        uint8_t *data_ptr,
        uint16_t param_list_length,
        uint8_t sense_len,
        uint32_t timeout
    )

    void scsi_read_buffer(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        int mode,
        uint8_t buffer_id,
        uint32_t offset,
        uint8_t *data_ptr,
        uint32_t allocation_length,
        uint8_t sense_len,
        uint32_t timeout
    )

    void scsi_write_buffer(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        int mode,
        uint8_t buffer_id,
        uint32_t offset,
        uint8_t *data_ptr,
        uint32_t param_list_length,
        uint8_t sense_len,
        uint32_t timeout
    )

    void scsi_read_write(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        int readop,
        uint8_t byte2,
        int minimum_cmd_size,
        uint64_t lba,
        uint32_t block_count,
        uint8_t *data_ptr,
        uint32_t dxfer_len,
        uint8_t sense_len,
        uint32_t timeout
    )

    void scsi_write_same(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        uint8_t byte2,
        int minimum_cmd_size,
        uint64_t lba,
        uint32_t block_count,
        uint8_t *data_ptr,
        uint32_t dxfer_len,
        uint8_t sense_len,
        uint32_t timeout
    )

    void scsi_ata_identify(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        uint8_t *data_ptr,
        uint16_t dxfer_len,
        uint8_t sense_len,
        uint32_t timeout
    )

    void scsi_ata_trim(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        uint16_t block_count,
        uint8_t *data_ptr,
        uint16_t dxfer_len,
        uint8_t sense_len,
        uint32_t timeout
    )

    void scsi_ata_pass_16(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint32_t flags,
        uint8_t tag_action,
        uint8_t protocol,
        uint8_t ata_flags,
        uint16_t features,
        uint16_t sector_count,
        uint64_t lba,
        uint8_t command,
        uint8_t control,
        uint8_t *data_ptr,
        uint16_t dxfer_len,
        uint8_t sense_len,
        uint32_t timeout
    )

    void scsi_unmap(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        uint8_t byte2,
        uint8_t *data_ptr,
        uint16_t dxfer_len,
        uint8_t sense_len,
        uint32_t timeout
    )

    void scsi_start_stop(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        int start,
        int load_eject,
        int immediate,
        uint8_t sense_len,
        uint32_t timeout
    )

    void scsi_read_attribute(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        uint8_t service_action,
        uint32_t element,
        uint8_t elem_type,
        int logical_volume,
        int partition,
        uint32_t first_attribute,
        int cache,
        uint8_t *data_ptr,
        uint32_t length,
        int sense_len,
        uint32_t timeout
    )

    void scsi_write_attribute(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        uint32_t element,
        int logical_volume,
        int partition,
        int wtc,
        uint8_t *data_ptr,
        uint32_t length,
        int sense_len,
        uint32_t timeout
    )

    void scsi_security_protocol_in(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        uint32_t security_protocol,
        uint32_t security_protocol_specific,
        int byte4,
        uint8_t *data_ptr,
        uint32_t dxfer_len,
        int sense_len,
        int timeout
    )

    void scsi_security_protocol_out(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        uint32_t security_protocol,
        uint32_t security_protocol_specific,
        int byte4,
        uint8_t *data_ptr,
        uint32_t dxfer_len,
        int sense_len,
        int timeout
    )

    void scsi_persistent_reserve_in(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        int service_action,
        uint8_t *data_ptr,
        uint32_t dxfer_len,
        int sense_len,
        int timeout
    )

    void scsi_persistent_reserve_out(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        int service_action,
        int scope,
        int res_type,
        uint8_t *data_ptr,
        uint32_t dxfer_len,
        int sense_len,
        int timeout
    )

    void scsi_report_supported_opcodes(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        int options,
        int req_opcode,
        int req_service_action,
        uint8_t *data_ptr,
        uint32_t dxfer_len,
        int sense_len,
        int timeout
    )


cdef extern from "cam/scsi/scsi_da.h" nogil:
    void scsi_format_unit(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        uint8_t byte2,
        uint16_t ileave,
        uint8_t *data_ptr,
        uint32_t dxfer_len,
        uint8_t sense_len,
        uint32_t timeout
    )


cdef extern from "cam/scsi/scsi_message.h":
    enum:
        MSG_CMDCOMPLETE
        MSG_TASK_COMPLETE
        MSG_EXTENDED
        MSG_SAVEDATAPOINTER
        MSG_RESTOREPOINTERS
        MSG_DISCONNECT
        MSG_INITIATOR_DET_ERR
        MSG_ABORT
        MSG_ABORT_TASK_SET
        MSG_MESSAGE_REJECT
        MSG_NOOP
        MSG_PARITY_ERROR
        MSG_LINK_CMD_COMPLETE
        MSG_LINK_CMD_COMPLETEF
        MSG_BUS_DEV_RESET
        MSG_TARGET_RESET
        MSG_ABORT_TAG
        MSG_ABORT_TASK
        MSG_CLEAR_QUEUE
        MSG_CLEAR_TASK_SET
        MSG_INIT_RECOVERY
        MSG_REL_RECOVERY
        MSG_TERM_IO_PROC
        MSG_CLEAR_ACA
        MSG_LOGICAL_UNIT_RESET
        MSG_QAS_REQUEST
        MSG_SIMPLE_Q_TAG
        MSG_SIMPLE_TASK
        MSG_HEAD_OF_Q_TAG
        MSG_HEAD_OF_QUEUE_TASK
        MSG_ORDERED_Q_TAG
        MSG_ORDERED_TASK
        MSG_IGN_WIDE_RESIDUE
        MSG_ACA_TASK
        MSG_IDENTIFYFLAG
        MSG_IDENTIFY_DISCFLAG
        MSG_IDENTIFY_LUNMASK
        MSG_EXT_SDTR
        MSG_EXT_SDTR_LEN
        MSG_EXT_WDTR
        MSG_EXT_WDTR_LEN
        MSG_EXT_WDTR_BUS_8_BIT
        MSG_EXT_WDTR_BUS_16_BIT
        MSG_EXT_WDTR_BUS_32_BIT
        MSG_EXT_PPR
        MSG_EXT_PPR_LEN
        MSG_EXT_PPR_PCOMP_EN
        MSG_EXT_PPR_RTI
        MSG_EXT_PPR_RD_STRM
        MSG_EXT_PPR_WR_FLOW
        MSG_EXT_PPR_HOLD_MCS
        MSG_EXT_PPR_QAS_REQ
        MSG_EXT_PPR_DT_REQ
        MSG_EXT_PPR_IU_REQ
        MSG_QUERY_TASK
        MSG_QUERY_TASK_SET
        MSG_QUERY_ASYNC_EVENT


cdef extern from "cam/ctl/ctl.h":
    ctypedef enum ctl_port_type:
        CTL_PORT_NONE
        CTL_PORT_FC
        CTL_PORT_SCSI
        CTL_PORT_IOCTL
        CTL_PORT_INTERNAL
        CTL_PORT_ISCSI
        CTL_PORT_SAS
        CTL_PORT_ALL
        CTL_PORT_ISC

    cdef struct ctl_port_entry:
        ctl_port_type port_type
        char port_name[64]
        int32_t targ_port
        int physical_port
        int virtual_port
        unsigned int flags
        uint64_t wwnn
        uint64_t wwpn
        int online


cdef extern from "cam/ctl/ctl_io.h":
    pass


cdef extern from "cam/ctl/ctl_backend.h":
    enum:
        CTL_BE_NAME_LEN


cdef extern from "cam/ctl/ctl_ioctl.h":
    enum:
        CTL_ERROR_STR_LEN
        
    enum:
        CTL_IO
        CTL_ENABLE_PORT
        CTL_DISABLE_PORT
        CTL_DELAY_IO
        CTL_ERROR_INJECT
        CTL_GET_OOA
        CTL_DUMP_STRUCTS
        CTL_LUN_REQ
        CTL_LUN_LIST
        CTL_ERROR_INJECT_DELETE
        CTL_SET_PORT_WWNS
        CTL_ISCSI
        CTL_PORT_REQ
        CTL_PORT_LIST
        CTL_LUN_MAP

    ctypedef enum ctl_iscsi_status:
        CTL_ISCSI_OK
        CTL_ISCSI_ERROR
        CTL_ISCSI_LIST_NEED_MORE_SPACE
        CTL_ISCSI_SESSION_NOT_FOUND

    ctypedef enum ctl_iscsi_type:
        CTL_ISCSI_HANDOFF
        CTL_ISCSI_LIST
        CTL_ISCSI_LOGOUT
        CTL_ISCSI_TERMINATE
        CTL_ISCSI_LISTEN
        CTL_ISCSI_ACCEPT
        CTL_ISCSI_SEND
        CTL_ISCSI_RECEIVE

    ctypedef enum ctl_lun_list_status:
        CTL_LUN_LIST_NONE
        CTL_LUN_LIST_OK
        CTL_LUN_LIST_NEED_MORE_SPACE
        CTL_LUN_LIST_ERROR

    cdef struct ctl_iscsi_list_params:
        uint32_t alloc_len
        char* conn_xml
        uint32_t fill_len
        int	spare[4]

    cdef union ctl_iscsi_data:
        ctl_iscsi_list_params list

    cdef struct ctl_iscsi:
        ctl_iscsi_type type
        ctl_iscsi_data data
        ctl_iscsi_status status
        char error_str[CTL_ERROR_STR_LEN]

    cdef struct ctl_lun_list:
        char backend[CTL_BE_NAME_LEN]
        uint32_t alloc_len
        char *lun_xml
        uint32_t fill_len
        ctl_lun_list_status status
        char error_str[CTL_ERROR_STR_LEN]


cdef extern from "cam/scsi/scsi_enc.h" nogil:
    enum:
        ENCIOC_GETNELM
        ENCIOC_GETELMMAP
        ENCIOC_GETENCSTAT
        ENCIOC_SETENCSTAT
        ENCIOC_GETELMSTAT
        ENCIOC_SETELMSTAT
        ENCIOC_GETTEXT
        ENCIOC_INIT
        ENCIOC_GETELMDESC
        ENCIOC_GETELMDEVNAMES
        ENCIOC_GETSTRING
        ENCIOC_SETSTRING
        ENCIOC_GETENCNAME
        ENCIOC_GETENCID

    ctypedef enum elm_type_t:
        ELMTYP_UNSPECIFIED
        ELMTYP_DEVICE
        ELMTYP_POWER
        ELMTYP_FAN
        ELMTYP_THERM
        ELMTYP_DOORLOCK
        ELMTYP_ALARM
        ELMTYP_ESCC
        ELMTYP_SCC
        ELMTYP_NVRAM
        ELMTYP_INV_OP_REASON
        ELMTYP_UPS
        ELMTYP_DISPLAY
        ELMTYP_KEYPAD
        ELMTYP_ENCLOSURE
        ELMTYP_SCSIXVR
        ELMTYP_LANGUAGE
        ELMTYP_COMPORT
        ELMTYP_VOM
        ELMTYP_AMMETER
        ELMTYP_SCSI_TGT
        ELMTYP_SCSI_INI
        ELMTYP_SUBENC
        ELMTYP_ARRAY_DEV
        ELMTYP_SAS_EXP
        ELMTYP_SAS_CONN

    enum:
        ENC_STRING_MAX

    cdef struct encioc_string:
        size_t bufsiz
        uint8_t *buf

    cdef struct encioc_element:
        unsigned int elm_idx
        unsigned int elm_subenc_id
        elm_type_t elm_type

    cdef struct encioc_elm_status:
        unsigned int elm_idx
        unsigned char cstat[4]

    cdef struct encioc_elm_desc:
        unsigned int elm_idx
        uint16_t elm_desc_len
        char *elm_desc_str

    cdef struct encioc_elm_devnames:
        unsigned int elm_idx
        size_t elm_names_size
        size_t elm_names_len
        char *elm_devnames

cdef extern from "cam/scsi/scsi_ses.h":
    enum:
        SES_ENCSTAT_UNRECOV
        SES_ENCSTAT_CRITICAL
        SES_ENCSTAT_NONCRITICAL
        SES_ENCSTAT_INFO
        SES_ENCSTAT_INVOP

    enum:
        SES_OBJSTAT_UNSUPPORTED
        SES_OBJSTAT_OK
        SES_OBJSTAT_CRIT
        SES_OBJSTAT_NONCRIT
        SES_OBJSTAT_UNRECOV
        SES_OBJSTAT_NOTINSTALLED
        SES_OBJSTAT_UNKNOWN
        SES_OBJSTAT_NOTAVAIL
        SES_OBJSTAT_NOACCESS


cdef extern from "dev/iscsi/iscsi_ioctl.h":
    enum:
        ISCSI_PATH
        ISCSI_NAME_LEN
        ISCSI_ADDR_LEN
        ISCSI_ALIAS_LEN
        ISCSI_SECRET_LEN
        ISCSI_OFFLOAD_LEN
        ISCSI_REASON_LEN

    enum:
        ISCSISADD
        ISCSISREMOVE
        ISCSISLIST
        ISCSISMODIFY

    cdef struct iscsi_session_conf:
        char isc_initiator[ISCSI_NAME_LEN]
        char isc_initiator_addr[ISCSI_ADDR_LEN]
        char isc_initiator_alias[ISCSI_ALIAS_LEN]
        char isc_target[ISCSI_NAME_LEN]
        char isc_target_addr[ISCSI_ADDR_LEN]
        char isc_user[ISCSI_NAME_LEN]
        char isc_secret[ISCSI_SECRET_LEN]
        char isc_mutual_user[ISCSI_NAME_LEN]
        char isc_mutual_secret[ISCSI_SECRET_LEN]
        int isc_discovery
        int isc_header_digest
        int isc_data_digest
        int isc_iser
        char isc_offload[ISCSI_OFFLOAD_LEN]
        int isc_enable
        int isc_dscp
        int isc_pcp
        int isc_spare[2]

    cdef struct iscsi_session_state:
        iscsi_session_conf iss_conf
        unsigned int iss_id
        char iss_target_alias[ISCSI_ALIAS_LEN]
        int iss_header_digest
        int iss_data_digest
        int iss_max_recv_data_segment_length
        int iss_max_burst_length
        int iss_first_burst_length
        int iss_immediate_data
        int iss_connected
        char iss_reason[ISCSI_REASON_LEN]
        char iss_offload[ISCSI_OFFLOAD_LEN]
        int iss_max_send_data_segment_length
        int iss_spare[3]

    cdef struct iscsi_session_add:
        iscsi_session_conf isa_conf
        int isa_spare[4]

    cdef struct iscsi_session_remove:
        unsigned int isr_session_id
        iscsi_session_conf isr_conf
        int isr_spare[4]

    cdef struct iscsi_session_list:
        unsigned int isl_nentries
        iscsi_session_state *isl_pstates
        int isl_spare[4]

    cdef struct iscsi_session_modify:
        unsigned int ism_session_id
        iscsi_session_conf ism_conf
        int ism_spare[4]


cdef extern from "cam/cam.h":
    enum:
        CAM_REQ_INPROG
        CAM_REQ_CMP
        CAM_REQ_ABORTED
        CAM_UA_ABORT
        CAM_REQ_CMP_ERR
        CAM_BUSY
        CAM_REQ_INVALID
        CAM_PATH_INVALID
        CAM_DEV_NOT_THERE
        CAM_UA_TERMIO
        CAM_SEL_TIMEOUT
        CAM_CMD_TIMEOUT
        CAM_SCSI_STATUS_ERROR
        CAM_MSG_REJECT_REC
        CAM_SCSI_BUS_RESET
        CAM_UNCOR_PARITY
        CAM_AUTOSENSE_FAIL
        CAM_NO_HBA
        CAM_DATA_RUN_ERR
        CAM_UNEXP_BUSFREE
        CAM_SEQUENCE_FAIL
        CAM_CCB_LEN_ERR
        CAM_PROVIDE_FAIL
        CAM_BDR_SENT
        CAM_REQ_TERMIO
        CAM_UNREC_HBA_ERROR
        CAM_REQ_TOO_BIG
        CAM_REQUEUE_REQ
        CAM_ATA_STATUS_ERROR
        CAM_SCSI_IT_NEXUS_LOST
        CAM_SMP_STATUS_ERROR
        CAM_REQ_SOFTTIMEOUT
        CAM_IDE
        CAM_RESRC_UNAVAIL
        CAM_UNACKED_EVENT
        CAM_MESSAGE_RECV
        CAM_INVALID_CDB
        CAM_LUN_INVALID
        CAM_TID_INVALID
        CAM_FUNC_NOTAVAIL
        CAM_NO_NEXUS
        CAM_IID_INVALID
        CAM_CDB_RECVD
        CAM_LUN_ALRDY_ENA
        CAM_SCSI_BUSY
        CAM_DEV_QFRZN
        CAM_AUTOSNS_VALID
        CAM_RELEASE_SIMQ
        CAM_SIM_QUEUED
        CAM_QOS_VALID
        CAM_STATUS_MASK
        CAM_SENT_SENSE

    ctypedef enum cam_error_string_flags:
        CAM_ESF_NONE
        CAM_ESF_COMMAND
        CAM_ESF_CAM_STATUS
        CAM_ESF_PROTO_STATUS
        CAM_ESF_ALL

    ctypedef enum cam_error_proto_flags:
        CAM_EPF_NONE
        CAM_EPF_MINIMAL
        CAM_EPF_NORMAL
        CAM_EPF_ALL
        CAM_EPF_LEVEL_MASK

    extern char * cam_error_string(cam_device *, ccb *, char *, int, cam_error_string_flags, cam_error_proto_flags)
